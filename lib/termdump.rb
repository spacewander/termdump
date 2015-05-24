require 'ostruct'
require 'optparse'

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

      ptree = Hash.new {|k, v| {}}
      pts.each_value do |processes|
        session_leader = processes[0]
        session = ptree[session_leader.ppid]
        processes[0] = session_cwd[session_leader.pid]
        session[session_leader.pid] = processes
        ptree[session_leader.ppid] = session
      end

      if @args.stdout
        print_tree ptree
      else
        dump ptree
      end
    end
  
    # print the process tree in yml with such format:
    # window0:
    #   tab0:cwd
    #   tab1:cwd
    #     command:comand
    # window1...
    def print_tree ptree
      win_order = 0
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
    # window0:
    #   tab0:cwd
    #   tab1:cwd
    #     command:comand
    # window1...
    def dump ptree
      
    end

  end

end

