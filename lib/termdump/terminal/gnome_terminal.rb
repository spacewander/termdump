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

    # Doing convertion below and join them with '+'
    # case 0 : <Ctrl><Shift><Alt><Super> => Ctrl Shift Alt Super
    # case 1 : [A-Z] => [a-z]
    # case 2 : <Primary> => Ctrl
    # case 3 : [0-9] [a-z] UpDownLeftRight F[0-12] Return space... => not changed
    # For example, 
    # '<Primary><Shift>A' => 'Ctrl+Shift+a'
    # '<Alt>space' => 'Alt+space'
    def convert_key_sequence in_sequence
      # copy and paste from terminal/terminator.rb
      in_sequence.tr_s!('[<>]', ' ')
      out_sequence = in_sequence.split.map do |key|
        if /^[[:upper:]]$/.match(key)
          key.downcase
        elsif key == 'Primary'
          'Ctrl'
        else
          key
        end
      end
      out_sequence.join('+')
    end

    def exec cwd, cmd
      sleep 0.5
      `xdotool getactivewindow type "cd #{cwd}\n"`
      `xdotool getactivewindow type "#{cmd}\n"` unless cmd.nil?
    end

    def window name, cwd, cmd
      # `getactivewindow key` not work on gnome-terminal, bug?
      `xdotool key #{configure 'new_window'}`
      exec cwd, cmd
    end

    def tab name, cwd, cmd
      `xdotool key #{configure 'new_tab'}`
      exec cwd, cmd
    end
  end
end

