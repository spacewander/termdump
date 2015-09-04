require_relative 'base/base'

module TermDump
  # This Terminal class is for xterm
  # See `man xterm`
  class Terminal < BasicTerminal
    def initialize config
      super config
    end

    def exec cwd, cmd
      wait_for_launching
      `xdotool getactivewindow type #{escape("cd #{cwd}\n")}`
      `xdotool getactivewindow type #{escape("#{cmd}\n")}` unless cmd.nil?
    end

    def window name, cwd, cmd
      IO.popen("xterm &") # `xterm &` is blocking
      exec cwd, cmd
    end
  end
end

