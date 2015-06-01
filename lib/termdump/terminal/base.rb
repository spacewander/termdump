module TermDump
  class BasicTerminal
    def initialize config
      @user_defined_config = config
      @config = {}
      @default_config = {}
    end

    # Get user defined value/configure value/default value with a configure item.
    # Raise keyError if value not found.
    def configure key
      @user_defined_config.fetch(key) {|key|
                                 @config.fetch(key) {|key| 
                                               @default_config.fetch(key)}}
    end

    # open a new window of this terminal automatically and focus on
    # +cwd+ is the directory the command executed in
    # +cmd+ if the cmd is nil, don't need to execute it; else execute the cmd
    def window cwd, cmd
      raise NotImplementedError.new("window should be implemented to open new window")
    end

    # open a new tab of this terminal automatically and focus on
    # implement it if your terminal support tabs
    # def tab(cwd, cmd); end

    # open a new vertical split of this terminal automatically and focus on
    # implement it if your terminal support tabs
    # def vsplit(cwd, cmd); end

    # open a new horizontal split of this terminal automatically and focus on
    # implement it if your terminal support tabs
    # def hsplit(cwd, cmd); end
  end
end
