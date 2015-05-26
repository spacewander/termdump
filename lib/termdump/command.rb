require 'fileutils'
require 'ostruct'
require 'optparse'
require 'yaml'

require 'termdump/version'

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
        args.size > 1 ? @args.session = args[1] : @args.list = true
        opts
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
      common_prefix = exact_commom_prefix(paths)
      if common_prefix != ''
        path_prefix = {'$PROJECT' => common_prefix}
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
        dump ptree, path_prefix
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

    @@session_dir = '~/.config/termdump/session'
    # save yml format string to a yml file in @@session_dir
    def save_to_file yml
      FileUtils.mkpath(@@session_dir) unless File.exist?(@@session_dir)
    end

    def list
      # TODO
    end
    def delete_session name
      # TODO
    end

    def edit_session name
      # TODO
    end
    def load_session name
      #ptree = load_file name
      #Session.new(ptree).replay
    end

    # load the process tree from yml format string
    def load_file
      # TODO
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

