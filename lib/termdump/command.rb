require 'fileutils'
require 'ostruct'
require 'optparse'
require 'yaml'

require 'termdump/version'
require 'termdump/session'

module TermDump
  class Process
    attr_accessor :pid, :ppid, :stat, :command
    def initialize pid, ppid, stat, command
      @pid = pid
      @ppid = ppid
      @stat = stat
      @command = command
    end

    def is_in_foreground
      @stat.start_with?('S') && @stat.include?('+')
    end

    def is_child_of process
      @ppid == process.pid
    end
  end

  class Command
    def initialize args
      @args = OpenStruct.new(:stdout => false, :action => :load, :list => false,
                             :session => '')
      OptionParser.new do |opts|
        opts.banner = "Usage: termdump [options] [session]"
        opts.on('-e', '--edit [session]', 'edit session') do |name|
          @args.action = :edit
          name.nil? ? @args.list = true : @args.session = name
        end
        opts.on('-d', '--delete [session]', 'delete session') do |name|
          @args.action = :delete
          name.nil? ? @args.list = true : @args.session = name
        end
        opts.on('-s', '--save [session]', 'save session') do |name|
          @args.action = :save
          name.nil? ? @args.list = true : @args.session = name
        end

        opts.on_tail('-l', '--list', 'list all sessions') { @args.list = true }
        opts.on_tail('-o', '--stdout', 'print dump result to stdout') {
          @args.stdout = true }
        opts.on_tail('-v', '--version', 'print version') do
          puts VERSION
          exit 0
        end
        opts.parse! args
        # :load is the default action if no option given
        if @args.action == :load
          args.size > 0 ? @args.session = args[0] : @args.list = true
        end
      end
    end

    def run
      if @args.action == :save
        save
      elsif @args.list
        list
      else
        name = @args.session
        case @args.action
        when :delete
          delete_session name
        when :edit
          edit_session name
        when :load
          load_session name
        end
      end
    end

    def save
      # TODO rewrite it once posixpsutil is mature
      this_pid = ::Process.pid.to_s
      pts = Hash.new {|k, v| []}
      session_leader_pids = []
      IO.popen('ps -eo pid,ppid,stat,tty,command').readlines.each do |entry|
        pid, ppid, stat, tty, command = entry.rstrip.split(' ', 5)
        if tty.start_with?('pts/')
          tty.sub!('pts/', '')
          # order by pid asc
          if pts[tty].empty?
            pts[tty] = [Process.new(pid, ppid, stat, command)]
            session_leader_pids.push(pid)
          elsif pts[tty].size == 1
            session_leader = pts[tty].first
            p = Process.new(pid, ppid, stat, command)
            if p.pid != this_pid && p.is_child_of(session_leader) && p.is_in_foreground
              pts[tty].push(p)
            end
          end
        end
      end

      # get cwd for each session
      session_cwd = {}
      IO.popen("pwdx #{session_leader_pids.to_s[1...-1].gsub(',', ' ')}") do |f|
        f.readlines.each do |entry|
          # 1234: /home/xxx/yyy...
          pid, cwd = entry.split(" ", 2)
          pid = pid[0...-1]
          session_cwd[pid] = cwd.rstrip
        end
      end

      paths = session_cwd.values
      path_prefix = {}
      common_prefix = exact_commom_prefix(paths)
      if common_prefix != ''
        path_prefix['$PROJECT'] = common_prefix
        session_cwd.each_value do |path|
          path.sub!(common_prefix, '${PROJECT}') if path.start_with?(common_prefix)
        end
      end

      ptree = Hash.new {|k, v| {}}
      pts.each_value do |processes|
        session_leader = processes[0]
        session = ptree[session_leader.ppid]
        processes[0] = session_cwd[session_leader.pid]
        session[session_leader.pid] = processes
        ptree[session_leader.ppid] = session
      end

      if @args.stdout
        print_result ptree, path_prefix
      else
        result = dump ptree, path_prefix
        save_to_file @args.session, result
      end
    end

    # return the common prefix of given paths. If the common prefix is '/' or '~',
    # or there is not common prefix at all, return ''
    def exact_commom_prefix paths
      home = Dir.home
      paths = paths.map do |path|
        new_path = path.sub!(home, '~') if path.start_with?(home)
        # handle '/xxx'
        new_path.nil? ? path.split('/') : new_path.split('/')
      end
      paths.sort! {|x, y| y.size <=> x.size }
      # indicate if we have found common preifx or just ignore all the case
      has_commom_prefix = false
      common_prefix = paths.reduce do |prefix, path|
        common_prefix = prefix
        prefix.each_with_index do |v, i|
          if v != path[i]
            common_prefix = prefix[0...i]
            break
          end
        end
        # common_prefix should longer than '~/' and '/'
        if common_prefix.size > 1
          has_commom_prefix = true
          common_prefix
        else
          # if there is not commom prefix between two path, just ignore it
          prefix
        end
      end
      has_commom_prefix && common_prefix.size > 1 ? common_prefix.join('/') : ''
    end

    # print the dumped result:
    def print_result ptree, path_prefix
      puts dump(ptree, path_prefix)
    end

    # dump the process tree in yml with such format:
    #   $0:xxx
    #   $1:...
    #   window0:
    #     tab0:
    #       cwd:
    #     tab1:
    #       cwd:
    #       command:comand
    #   window1...
    #
    # return a yml format string
    def dump ptree, path_prefix
      yml_tree = {}
      path_prefix.each_pair do |k, v|
        yml_tree[k] = v
      end

      win_order = 0
      ptree.each_value do |session|
        order = 0
        tab_tree = {}
        session.each_value do |v|
          tab_node = {'cwd' => v[0]}
          tab_node["command"] = v[1].command if v.size > 1
          tab_tree["tab#{order}"] = tab_node
          order += 1
        end
        yml_tree["window#{win_order}"] = tab_tree
        win_order += 1
      end
      yml_tree.to_yaml
    end

    @@session_dir = "#{Dir.home}/.config/termdump/session"
    # save yml format string to a yml file in @@session_dir
    def save_to_file session_name, result
      begin
        if session_name != ''
          status = search_session session_name
          overwrite = false
          if status[:exist]
            print "#{status[:name]} already exists, overwrite?[Y/N]:"
            answer = $stdin.gets.chomp
            overwrite = true if answer == 'Y' || answer == 'y'
          end
          if !status[:exist] || overwrite
            IO.write status[:name], result
            puts "Save session '#{session_name}' successfully"
            return
          end
        end
        print "Enter a new session name:"
        name = $stdin.gets.chomp
        save_to_file name, result
      rescue Errno::ENOENT
        FileUtils.mkpath(@@session_dir) unless File.exist?(@@session_dir)
        save_to_file session_name, result # reentry
      end
    end

    def list
      begin
        Dir.chdir(@@session_dir)
        sessions = Dir.glob('*.yml')
        if sessions.empty?
          puts "No session exists in #{@@session_dir}"
        else
          puts "order:\tsession name\tctime\t\tatime"
          sessions.each_with_index do |f, i|
            cdate = File.ctime(f).to_date.strftime
            adate = File.atime(f).to_date.strftime
            f.sub!(/\.yml$/, '')
            puts format("[%d]: %15s\t%s\t%s", i, f, cdate, adate)
          end

          get_input_order = proc do |action, &handler|
            print "Select one session to #{action}:"
            order = $stdin.gets.chomp
            if order.to_i != 0 || order == '0' # can order be an integer?
              order = order.to_i
              if 0 <= order && order < sessions.size
                handler.call sessions[order]
                return
              end
            end
            puts "Received a wrong session order"
          end

          case @args.action
          when :load, :edit, :delete
            get_input_order.call(@args.action) { |session|
              send("#{@args.action}_session", session) }
          end
        end
      rescue Errno::ENOENT
        FileUtils.mkpath(@@session_dir) unless File.exist?(@@session_dir)
      end
    end

    def delete_session name
      status = search_session name
      return puts "#{status[:name]} not found" unless status[:exist]
      File.delete status[:name]
      puts "Delete session '#{name}' successfully"
    end

    def edit_session name
      FileUtils.mkpath(@@session_dir) unless File.exist?(@@session_dir)
      status = search_session name
      return puts "#{status[:name]} not found" unless status[:exist]
      return puts "Set $EDITOR as your favourite editor to edit the session" unless ENV['EDITOR']
      exec ENV['EDITOR'], status[:name]
    end

    def load_session name
      ptree = load_file name
      if ptree != {}
        ptree = parse_variables ptree
        Session.new.replay(ptree)
      end
    end

    # load the process tree from yml format string
    def load_file name
      status = search_session name
      unless status[:exist]
        puts "#{status[:name]} not found"
        {}
      else
        YAML.load(IO.read(status[:name]))
      end
    end

    def parse_variables ptree
      # rewrite with tap for ruby > 1.9
      variables = ptree.select {|k, v| k.start_with?('$')}
      ptree.delete_if {|k, v| k.start_with?('$')}
      var = Regexp.new(/(?<!\\) # don't trap in \$
                       \$\{
                        .*?[^\\] # parse the name until }(but not \})
                       \}/mix).freeze
      scan_tree = proc do |node|
        node.each_pair do |k, v|
          if k == 'cwd'
            node[k].gsub!(var) do |match|
              # match is sth like ${foo}
              variables['$' + match[2...-1]]
            end
          elsif v.is_a?(Hash)
            scan_tree.call v
          end
        end
      end

      ptree.each_pair {|k, v| scan_tree.call v if k.start_with?('window')}
      ptree
    end

    # return a Hash with two symbols:
    #   :exist => is session already existed
    #   :name => the absolute path of session
    def search_session name
      session_name = File.join(@@session_dir, name + ".yml")
      {:exist => File.exist?(session_name), :name => session_name}
    end
  end

end

