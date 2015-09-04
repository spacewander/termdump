require_relative './terminal_helper'

module TermDump
  class BasicTerminal
    include TerminalHelper

    attr_writer :delay
    def initialize config
      @user_defined_config = config
      @config = {}
      @default_config = {}

      @delay = 0.5 # delay for 0.5 second
    end

    # Get user defined value/configure value/default value with a configure item.
    # Raise keyError if value not found.
    def configure configure_key
      @user_defined_config.fetch(configure_key) {|key_in_config|
        @config.fetch(key_in_config) {|default_key|
          @default_config.fetch(default_key)
        }
      }
    end

    # wait until shell/terminal launched, so that we can do something in them
    def wait_for_launching
      sleep @delay
    end

    # run command in current window
    # +cwd+ is the directory the command executed in
    # +cmd+ if the cmd is nil, don't need to execute it; else execute the cmd
    def exec cwd, cmd
      raise NotImplementedError.new(
        "exec should be implemented to execute cmd on current window")
    end

    # open a new window of this terminal automatically and focus on
    # +name+ is the name of new window
    # +cwd+ is the directory the command executed in
    # +cmd+ if the cmd is nil, don't need to execute it; else execute the cmd
    def window name, cwd, cmd
      raise NotImplementedError.new(
        "window should be implemented to open new window")
    end

    # open a new tab of this terminal automatically and focus on
    # implement it if your terminal support tabs
    # def tab(name, cwd, cmd); end

    # open a new vertical split of this terminal automatically and focus on
    # implement it if your terminal support tabs
    # def vsplit(name, cwd, cmd); end

    # open a new horizontal split of this terminal automatically and focus on
    # implement it if your terminal support tabs
    # def hsplit(name, cwd, cmd); end
  end
end
