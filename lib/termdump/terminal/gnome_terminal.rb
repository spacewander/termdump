require_relative 'base/base'

module TermDump
  # This Terminal class is for [gnome-terminal](https://wiki.gnome.org/Apps/Terminal)
  class Terminal < BasicTerminal
    def initialize config
      @user_defined_config = config
      @keybindings = '/apps/gnome-terminal/keybindings'
      @config = {
        'new_window' => get_configure_key('new_window'),
        'new_tab' => get_configure_key('new_tab')
      }

      @default_config = {
        'new_window' => 'ctrl+alt+t',
        'new_tab' => 'ctrl+shift+t',
      }
    end

    def get_configure_key key
      value = IO.popen(
        "gconftool -g '#{@keybindings}/#{key}' 2>/dev/null").read.chomp
      convert_key_sequence(value) if value != ''
    end

    def exec cwd, cmd
      sleep 0.5
      `xdotool getactivewindow type #{escape("cd #{cwd}\n")}`
      `xdotool getactivewindow type #{escape("#{cmd}\n")}` unless cmd.nil?
    end

    def window name, cwd, cmd
      # `getactivewindow key` not work on gnome-terminal
      `xdotool key #{configure 'new_window'}`
      exec cwd, cmd
    end

    def tab name, cwd, cmd
      `xdotool key #{configure 'new_tab'}`
      exec cwd, cmd
    end
  end
end

