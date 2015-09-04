require_relative 'base/base'

module TermDump
  # This Terminal class is for [tilda](https://github.com/lanoxx/tilda)
  # See `man tilda` and <https://github.com/lanoxx/tilda>
  class Terminal < BasicTerminal
    def initialize config
      super config

      # FIXME Could not detect the order of current tilda window, 
      # so guess it to be the first one
      #
      # Each tilda window with order x can be toggled by Fx, for example,
      # the first one is toggled by F1; and use config_(x-1) as its configure.
      configure = "#{Dir.home}/.config/tilda/config_0"
      if File.exist?(configure)
        lines = IO.readlines(configure)
        @config = parse_configure lines
      end

      @default_config = {
        'new_window' => 'F1',
        'new_tab' => 'ctrl+shift+t'
      }
    end

    @@CONFIGURE_KEY_MAPPER = {
      'addtab_key' => 'new_tab',
      'key' => 'new_window'
    }

    def parse_configure lines
      config = {}
      lines.each do |line|
        line.lstrip!
        unless line.start_with?('#')
          key, value = line.split('=', 2)
          key.strip!
          key = @@CONFIGURE_KEY_MAPPER[key]
          value = value.match('\A\s*"(.*?)"')
          unless key.nil? || value.nil?
            config[key] = convert_key_sequence(value[1])
          end # need to handle key
        end # not a comment line
      end
      config
    end

    # Each tilda's window is toggled by different key binding,
    # For example, first tilda window is toggled by F1, second one by F2, ...
    # To keep simple, treat window as tab
    def window name, cwd, cmd
      tab name, cwd, cmd
    end

    def tab name, cwd, cmd
      # `getactivewindow key` not work on tilda
      `xdotool key #{configure 'new_tab'}`
      exec cwd, cmd
    end

    def exec cwd, cmd
      wait_for_launching
      `xdotool getactivewindow type #{escape("cd #{cwd}\n")}`
      `xdotool getactivewindow type #{escape("#{cmd}\n")}` unless cmd.nil?
    end
  end
end
