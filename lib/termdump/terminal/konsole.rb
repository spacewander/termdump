require_relative 'base/base'

module TermDump
  # This Terminal class is for
  # [konsole](https://konsole.kde.org/)
  # See https://docs.kde.org/stable5/en/applications/konsole/index.html
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
      `konsole --workdir #{escape cwd}`
      wait_for_launching
      `xdotool getactivewindow type #{escape("#{cmd}\n")}` unless cmd.nil?
    end

    def tab name, cwd, cmd
      `konsole --workdir #{escape cwd} --new-tab`
      wait_for_launching
      `xdotool getactivewindow type #{escape("#{cmd}\n")}` unless cmd.nil?
    end
    # konsoe's split is not real. It just make another duplicate session.
  end
end
