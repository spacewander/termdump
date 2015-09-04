require_relative 'base/base'

module TermDump
  # This Terminal class is for 
  # [urxvt](http://software.schmorp.de/pkg/rxvt-unicode.html)
  # See `man urxvt` and `man 7 urxvt`
  class Terminal < BasicTerminal
    def initialize config
      super config
      # urxvt's configure is written with perl. It is too difficult to get the 
      # binding key value. So here we pass the responsibility of setting key binding 
      # to the users.
      @default_config = {
        # there is no default new_window key binding in urxvt
        'new_window' => nil,
        'new_tab' => 'shift+Down', # it should be 'Down' not 'down'
      }
    end

    def exec cwd, cmd
      wait_for_launching
      `xdotool getactivewindow type #{escape("cd #{cwd}\n")}`
      `xdotool getactivewindow type #{escape("#{cmd}\n")}` unless cmd.nil?
    end

    def window name, cwd, cmd
      if configure 'new_window'
        `xdotool getactivewindow key #{configure 'new_window'}`
      else
        `xdotool getactivewindow type 'urxvt &\n'`
        wait_for_launching
      end
      exec cwd, cmd
    end

    def tab name, cwd, cmd
      # use `urxvt -pe tabbed` to enable tab support
      `xdotool getactivewindow key #{configure 'new_tab'}`
      exec cwd, cmd
    end
  end
end
