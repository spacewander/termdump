require_relative 'base'

module TermDump
  class Terminal < BasicTerminal
    def initialize config
      # the config file will be ~/.config/terminator/config, 
      # but it may be overridden with $XDG_CONFIG_HOME 
      # (in which case it will be $XDG_CONFIG_HOME/terminator/config)
      if ENV['XDG_CONFIG_HOME'].nil?
        configure = "#{Dir.home}/.config/terminator/config"
      else
        configure = "#{ENV['XDG_CONFIG_HOME']}/terminator/config"
      end
      lines = IO.readlines(configure) if File.exist?(configure)
      @config = parse_configure lines
      @default_config = {
        'new_window' => 'ctrl+shift+i',
        'new_tab' => 'ctrl+shift+t',
        'new_vsplit' => 'ctrl+shift+e',
        'new_hsplit' => 'ctrl+shift+o'
      }
    end

    CONFIGURE_KEY_MAPPER = {
      'new_tab' => 'new_tab',
      'split_vert' => 'new_vsplit',
      'split_horiz' => 'new_hsplit',
      'new_window' => 'new_window'
    }
    # Parse lines and fill @config with key mapper result.
    #
    # The configure format of terminator:
    #[keybindings]
    #  full_screen = <Ctrl><Shift>F11
    #
    # We only care about the keybindings.
    def parse_configure lines
      config = {}
      in_keybindings = false
      lines.each do |line|
        line.rstrip!
        if in_keybindings
          if line.start_with?('[') || line == ''
            in_keybindings = false
          else
            key, value = line.split('=', 2)
            key.strip!
            first, second, third = value.rpartition('#')
            value = (first != "" ? first.strip : third.strip)
            key = CONFIGURE_KEY_MAPPER[key]
            unless key.nil? || value == ''
              config[key] = convert_key_sequence(value)
            end
          end
        end 
        in_keybindings = true if line == '[keybindings]'
      end
      config
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
      # TODO
    end

    def window name, cwd, cmd
      # TODO
    end

    def tab name, cwd, cmd
      # TODO
    end

    def vsplit name, cwd, cmd
      # TODO
    end

    def hsplit name, cwd, cmd
      # TODO
    end
  end
end
