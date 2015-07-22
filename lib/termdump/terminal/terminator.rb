require_relative 'base/base'

module TermDump
  # This Terminal class is for [terminator](http://gnometerminator.blogspot.sg/p/introduction.html)
  # See `man terminator` and `man termintor_config`
  class Terminal < BasicTerminal
    def initialize config
      @user_defined_config = config
      # the config file will be ~/.config/terminator/config, 
      # but it may be overridden with $XDG_CONFIG_HOME 
      # (in which case it will be $XDG_CONFIG_HOME/terminator/config)
      if ENV['XDG_CONFIG_HOME'].nil?
        configure = "#{Dir.home}/.config/terminator/config"
      else
        configure = "#{ENV['XDG_CONFIG_HOME']}/terminator/config"
      end
      if File.exist?(configure)
        lines = IO.readlines(configure)
        @config = parse_configure lines
      else
        @config = {}
      end
      @default_config = {
        'new_window' => 'ctrl+shift+i',
        'new_tab' => 'ctrl+shift+t',
        'new_vsplit' => 'ctrl+shift+e',
        'new_hsplit' => 'ctrl+shift+o'
      }
    end

    @@CONFIGURE_KEY_MAPPER = {
      'new_tab' => 'new_tab',
      'split_vert' => 'new_vsplit',
      'split_horiz' => 'new_hsplit',
      'new_window' => 'new_window'
    }
    # Parse lines and fill @config with key mapper result.
    #
    # The configure format of terminator:
    #[keybindings]
    #  full_screen = <Ctrl><Shift>F11 # ...
    #  # ...
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
            unless line.start_with?('#')
              key, value = line.split('=', 2)
              key.strip!
              first, _, third = value.rpartition('#')
              value = (first != "" ? first.strip : third.strip)
              key = @@CONFIGURE_KEY_MAPPER[key]
              unless key.nil? || value == ''
                config[key] = convert_key_sequence(value)
              end
            end
          end

        end  # end in keybindings
        in_keybindings = true if line == '[keybindings]'
      end
      config
    end

    def exec cwd, cmd
      sleep 0.5
      `xdotool getactivewindow type #{escape("cd #{cwd}\n")}`
      `xdotool getactivewindow type #{escape("#{cmd}\n")}` unless cmd.nil?
    end

    def window name, cwd, cmd
      `xdotool getactivewindow key #{configure 'new_window'}`
      exec cwd, cmd
    end

    def tab name, cwd, cmd
      `xdotool getactivewindow key #{configure 'new_tab'}`
      exec cwd, cmd
    end

    def vsplit name, cwd, cmd
      `xdotool getactivewindow key #{configure 'new_vsplit'}`
      exec cwd, cmd
    end

    def hsplit name, cwd, cmd
      `xdotool getactivewindow key #{configure 'new_hsplit'}`
      exec cwd, cmd
    end
  end
end
