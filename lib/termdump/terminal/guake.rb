require_relative 'base/base'

module TermDump
  # This Terminal class is for [guake](http://guake-project.org/)
  # See `man guake`
  class Terminal < BasicTerminal
    def initialize config
      @user_defined_config = config
      @keybindings = '/apps/guake/keybindings/local'
      @config = {
        'new_tab' => get_configure_key('new_tab')
      }

      @default_config = {
        'new_window' => 'F12',
        'new_tab' => 'ctrl+shift+t'
      }
    end

    def get_configure_key key
      value = IO.popen(
        "gconftool -g '#{@keybindings}/#{key}' 2>/dev/null").read.chomp
      value if value != ''
    end

    # There is no 'window' concept in guake. 
    # Only one terminal instance exists all the time. So treat it as tab
    def window name, cwd, cmd
      tab name, cwd, cmd
    end

    def tab name, cwd, cmd
      with_name = ''
      with_cwd = ''
      with_cmd = ''
      with_name = "-r #{escape(name)}" unless name.nil? || name == ''
      with_cwd = "-n #{escape(cwd)}" unless cwd.nil? || cwd == ''
      with_cmd = "-e #{escape(cmd)}" unless cmd.nil? || cmd == ''
      `guake #{with_name} #{with_cwd} #{with_cmd}`
    end

    def exec cwd, cmd
      exec_cmd = "cd #{cwd}"
      exec_cmd += " && #{cmd}" unless cmd.nil? || cmd == ''
      `guake -e #{escape(exec_cmd)}`
    end
  end
end
