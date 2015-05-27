module TermDump
  class BasicTerminal
    attr_reader :support_tab, :support_split

    def initialize
    end

    # run command automatically
    def exec cmd
      raise NotImplementedError.new("exec should be implemented to execute command")
    end

    # open a new window of this terminal automatically and focus on
    # (option) you may set the name of the new window to name
    def new_window name
      raise NotImplementedError.new("new_window should be implemented to open new window")
    end

    # open a new tab of this terminal automatically and focus on
    # implement it if your terminal support tabs
    # def tab
    # end

    # open a new split of this terminal automatically and focus on
    # implement it if your terminal support tabs
    # def split
    # end
  end

  class Terminal < BasicTerminal 
  end
end
