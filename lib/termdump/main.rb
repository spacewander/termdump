require 'fileutils'
require 'pathname'
require 'yaml'

require 'termdump/process'
require 'termdump/session'

module TermDump
  class SessionSyntaxError < StandardError; end

  class Main
    BASE_DIR = "#{Dir.home}/.config/termdump/" # only for posix file system
    @@session_dir = BASE_DIR + "session"
    @@config_file = BASE_DIR + "config.yml"
    @@session_extname = '.yml'

    def initialize
      @config = read_configure 
    end

    # Read configure from @@config_file if this file exists and return a Hash as result.
    # The configure format is yaml.
    def read_configure
      config = {}
      config = YAML.load(IO.read(@@config_file)) if File.exist? @@config_file
      config
    end

    # initialize configure and session directory interactively
    def init
      if Dir.exist?(@@config_file)
        return puts "The configure has been initialized yet"
      end
      dir = File.dirname(File.realpath(__FILE__)) # for ruby > 2.0.0, use __dir__
      files = File.join(dir, 'terminal', '*.rb')
      support_term = Dir.glob(files).map {|fn| File.basename(fn, '.rb')}

      puts "Currently support terminals:"
      support_term.each_with_index {|term, i| puts "[#{i}]\t#{term}"}
      print "Select your terminal: "
      choice = $stdin.gets.chomp
      if choice.to_i != 0 || choice == '0'
        choice = choice.to_i
        if 0 <= choice && choice < support_term.size
          print "Will create #{@@config_file} and #{@@session_dir}, go on?[Y/N] "
          answer = $stdin.gets.chomp
          return if answer == 'N' || answer == 'n'
          configure = {
            'terminal' => support_term[choice]
          }
          FileUtils.mkpath(BASE_DIR) unless Dir.exist?(BASE_DIR)
          IO.write @@config_file, YAML.dump(configure)
          FileUtils.mkdir(@@session_dir) unless Dir.exist?(@@session_dir)
          puts "Ok, the configure is initialized now. Happy coding!"
          return
        end
      end
      puts "Incorrect choice received!"
    end

    # Save the session into session file.
    # If +print_stdout+ is true, print to stdout instead of saving it.
    # If +exclude_current_pty+ is true, save all pty instead of the current one
    def save session_name, print_stdout, exclude_current_pty
      # TODO rewrite it once posixpsutil is mature
      this_pid = ::Process.pid.to_s
      pts = Hash.new {|k, v| []}
      this_terminal_pid = nil

      IO.popen('ps -eo pid,ppid,stat,tty,command').readlines.each do |entry|
        pid, ppid, stat, tty, command = entry.rstrip.split(' ', 5)
        if tty.start_with?('pts/')
          tty.sub!('pts/', '')
          # order by pid asc
          case pts[tty].size
          when 0
            pts[tty] = [Process.new(pid, ppid, stat, command)]
          else
            session_leader = pts[tty].first
            p = Process.new(pid, ppid, stat, command)

            # this_terminal_pid -> session_leader_pids -> 
            #   foreground_pids(exclude this_pid)
            if p.pid == this_pid
              this_terminal_pid = session_leader.ppid
            elsif p.is_child_of(session_leader) && p.is_in_foreground
              pts[tty].push(p)
            end
          end

        end
      end

      if exclude_current_pty
        this_ppid = ::Process.ppid.to_s
        pts.reject! do |tty, processes| 
          session_leader = processes.first
          session_leader.ppid != this_terminal_pid || session_leader.pid == this_ppid
        end
      else
        pts.reject! {|tty, processes| processes.first.ppid != this_terminal_pid }
      end
      return if pts.empty?

      # get cwd for each session
      session_cwd = {}
      session_leader_pids = pts.values.map { |processes|
        processes.first.pid
      }.join(' ')
      IO.popen("pwdx #{session_leader_pids}") do |f|
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

      if print_stdout
        print_result ptree, path_prefix
      else
        result = dump ptree, path_prefix
        save_to_file session_name, result
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
    #     cwd:
    #     tab0:
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
          if order == 0
            tab_tree['cwd'] = v[0]
            tab_tree["command"] = v[1].command if v.size > 1
          else
            tab_node = {'cwd' => v[0]}
            tab_node["command"] = v[1].command if v.size > 1
            tab_tree["tab#{order-1}"] = tab_node
          end
          order += 1
        end
        yml_tree["window#{win_order}"] = tab_tree
        win_order += 1
      end
      yml_tree.to_yaml
    end

    # If name is an absolute path(with or without session extname), 
    # check if the session exists;
    # otherwises search session file first in current path and then in session_dir
    #
    # return a Hash with two symbols:
    #   :exist => is session already existed
    #   :name => the absolute path of session
    def search_session name
      if File.extname(name) != @@session_extname
        name = name + @@session_extname
      end

      status = {:exist => File.exist?(name), :name => name}
      if !status[:exist] && Pathname.new(name).relative?
        session_name = File.join(Dir.pwd, name)
        status = {:exist => File.exist?(session_name), :name => session_name}
        unless status[:exist]
          session_name = File.join(@@session_dir, name)
          status = {:exist => File.exist?(session_name), :name => session_name}
        end
      end
      status
    end

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

    def list list_action
      begin
        sessions = Dir.glob("#{@@session_dir}/*#{@@session_extname}")
        sessions += Dir.glob("#{Dir.pwd}/*#{@@session_extname}")
        if sessions.empty?
          puts "No session exists in #{@@session_dir}"
        else
          puts "order:\tsession name\tctime                   atime"
          sessions.sort!{|x, y| File.atime(y) <=> File.atime(x) }
          sessions.each_with_index do |f, i|
            # equal to yy-MM-dd hh:mm:ss
            cdate = File.ctime(f).strftime('%F %T')
            adate = File.atime(f).strftime('%F %T')
            is_pwd = f.start_with?(Dir.pwd)
            # remain the path in sessions absolute
            f = File.basename(f, @@session_extname)
            f = "[pwd]#{f}" if is_pwd
            printf("[%d]: %15s\t%s\t%s\n", i, f, cdate, adate)
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

          case list_action
          when :load, :edit, :delete
            get_input_order.call(list_action) { |session|
              send("#{list_action}_session", session) }
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
      puts "Delete session '#{status[:name]}' successfully"
    end

    def edit_session name
      FileUtils.mkpath(@@session_dir) unless File.exist?(@@session_dir)
      status = search_session name
      return puts "#{status[:name]} not found" unless status[:exist]
      return puts "Set $EDITOR as your favourite editor to edit the session" unless ENV['EDITOR']
      exec ENV['EDITOR'], status[:name]
    end

    # load the process tree from yml format string, and replay it
    def load_session name
      status = search_session name
      return puts "#{status[:name]} not found" unless status[:exist]
      ptree = YAML.load(IO.read(status[:name]))
      if ptree.is_a?(Hash) && ptree != {}
        begin
          ptree = check ptree
        rescue SessionSyntaxError => e
          puts "Parse session file error: #{e.message}"
          exit 1
        end
        Session.new(@config).replay(ptree)
      else
        raise SessionSyntaxError.new("yml format error")
      end
    end

    # Raise SessionSyntaxError if their is syntax error in session file.
    # Session file format:
    #   $variables...
    #   window0:
    #     cwd:
    #     command:
    #     tab0:
    #       cwd:
    #       vsplit:
    #       hsplit:
    # Restriction:
    #   1. There are only four types of node: :window, :tab, :vsplit and :hsplit
    #   2. node level: :window > :tab > :vsplit, :hsplit
    #   3. The root node should be :window
    #   4. The root node should have a cwd attributes.
    #      If a node itself does not have cwd attributes, it inherits its parent's
    #   5. Each node has only one 'cwd' and at most one 'command'
    #   6. the type of 'cwd' and 'command' is String
    def check ptree
      # (5) is ensured by yml syntax
      parse_variables ptree
      ptree.each_pair do |k, node|
        check_node node, :window if k.start_with?("window")
      end
      ptree
    end

    def check_node node, node_type, parent_cwd=''
      unless node.is_a?(Hash)
        raise SessionSyntaxError.new("#{node_type} should be a node") 
      end
      if node.has_key?('cwd')
        path = node['cwd']
        unless path.is_a?(String)
          raise SessionSyntaxError.new("'cwd' should be a String")
        end
        unless Pathname.new(path).absolute?
          if parent_cwd == ''
            msg = "missing base working directory for relative path #{path}"
            raise SessionSyntaxError.new(msg)
          end
          path = File.absolute_path(path, parent_cwd)
          node['cwd'] = path
        end
        unless check_cwd_cd_able path
          raise SessionSyntaxError.new("can't cd to #{path}") 
        end
      else
        if parent_cwd == ''
          raise SessionSyntaxError.new("'cwd' not found in #{node_type}") 
        end
        node['cwd'] = parent_cwd
      end
      cwd = node['cwd']

      if node.has_key?('command')
        unless node['command'].is_a?(String)
          raise SessionSyntaxError.new("'command' should be a String")
        end
      end

      remain_attributes = ['cwd', 'command']
      case node_type
      when :window
        node.each_pair do |attr, value|
          if attr.start_with?('window')
            check_node value, :window, cwd
          elsif attr.start_with?('tab')
            check_node value, :tab, cwd
          elsif attr.start_with?('vsplit')
            check_node value, :vsplit, cwd
          elsif attr.start_with?('hsplit')
            check_node value, :hsplit, cwd
          elsif !remain_attributes.include?(attr)
            node.delete attr
          end
        end
      when :tab
        node.each_pair do |attr, value|
          if attr.start_with?('tab')
            check_node value, :tab, cwd
          elsif attr.start_with?('vsplit')
            check_node value, :vsplit, cwd
          elsif attr.start_with?('hsplit')
            check_node value, :hsplit, cwd
          elsif !remain_attributes.include?(attr)
            node.delete attr
          end
        end
      when :vsplit, :hsplit
        node.each_pair do |attr, value|
          if attr.start_with?('vsplit')
            check_node value, :vsplit, cwd
          elsif attr.start_with?('hsplit')
            check_node value, :hsplit, cwd
          elsif !remain_attributes.include?(attr)
            node.delete attr
          end
        end
      end
    end

    # +path+ is absolute path
    def check_cwd_cd_able path
      Dir.exist?(path) && File.readable?(path)
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
            cwd = node[k]
            cwd.gsub!(var) do |match|
              # match is sth like ${foo}
              name = match[2...-1]
              value = variables['$' + name]
              # Enter value for unknown variables
              if value.nil?
                print "Enter the value of '#{name}':"
                value = $stdin.gets.chomp
              end
              value
            end
            cwd.sub!('~', Dir.home) if cwd == '~' || cwd.start_with?('~/')
          elsif v.is_a?(Hash)
            scan_tree.call v
          end
        end
      end

      ptree.each_pair {|k, v| scan_tree.call v if k.start_with?('window')}
    end
  end

end

