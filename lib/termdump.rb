require 'fileutils'
require 'ostruct'
require 'optparse'
require 'yaml'

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
    @@version = '0.0.1'

    def initialize args
      @args = OpenStruct.new(:stdout => false)
      OptionParser.new do |opts|
        opts.banner = "Usage: termdump [options]"
        opts.on('-o', '--stdout', 'print dump result to stdout') {
          |v| @args.stdout = true }
        opts.on('-v', '--version', 'print version') do 
          puts @@version
          exit 0
        end
        opts.parse! args
      end
    end

    def run
      # TODO rewrite it once posixpsutil is mature
      this_pid = ::Process.pid.to_s
      pts = Hash.new {|k, v| []}
      session_leader_pids = []
      IO.popen('ps -eo pid,ppid,stat,tty,command').readlines.each do |entry|
        pid, ppid, stat, tty, command = entry.chomp.split(' ', 5)
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
      path_prefix = {'$PROJECT' => common_prefix}
      session_cwd.each_value do |path|
        path.sub!(common_prefix, '$PROJECT') if path.start_with?(common_prefix)
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
  
    # print the process tree with such format:
    # $0:xxx
    # $1:...
    # window0:
    #   tab0:cwd
    #   tab1:cwd
    #     command:comand
    # window1...
    def print_result ptree, path_prefix
      win_order = 0
      path_prefix.each_pair {|k, v| puts "#{k}:#{v}"}
      ptree.each_value do |session|
        entry = "window#{win_order}:\n"
        order = 0
        session.each_value do |v|
          entry += "\ttab#{order}:\n\t\tcwd:#{v[0]}\n"
          entry += "\t\tcommand:#{v[1].command}\n" if v.size > 1
          order += 1
        end
        puts entry
        win_order += 1
      end
    end

    # dump the process tree in yml with such format:
    #   $0:xxx
    #   $1:...
    #   window0:
    #     tab0:cwd
    #     tab1:cwd
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
      puts yml_tree.to_yaml
    end

    @@save_dir = '~/.config/termdump'
    # save yml format string to a yml file in ~/.config/termdump
    def save yml
      FileUtils.mkpath(@@save_dir) unless File.exist?(@@save_dir)
    end

    # load the process tree from yml format string
    def load
      # TODO
    end

    # return the common prefix of given paths
    def exact_commom_prefix paths
      home = Dir.home
      paths = paths.map do |path| 
        new_path = path.sub!(home, '~') if path.start_with?(home)
        # handle '/'
        new_path.nil? ? path.split : new_path.split
      end
      common_prefix = paths.reduce do |prefix, path|
        common_prefix = prefix
        prefix.each_with_index do |v, i|
          if v != path[i]
            common_prefix = prefix[0...i]
          end
        end
        # common_prefix longer than '~/' and '/'
        common_prefix.size > 2 ? common_prefix : prefix
      end
      common_prefix.join('/')
    end
  end

end

