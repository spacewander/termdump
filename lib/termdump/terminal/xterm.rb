require_relative 'base/base'

module TermDump
  # This Terminal class is for xterm
  # See `man xterm`
  class Terminal < BasicTerminal
    def initialize config
    end

    def exec cwd, cmd
      sleep 0.5
      `xdotool getactivewindow type #{escape("cd #{cwd}\n")}`
      `xdotool getactivewindow type #{escape("#{cmd}\n")}` unless cmd.nil?
    end

    def window name, cwd, cmd
      IO.popen("xterm &") # `xterm &` is blocking
      exec cwd, cmd
    end
  end
end

