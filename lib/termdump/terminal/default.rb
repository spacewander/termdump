require_relative 'base'

module TermDump
  class Terminal < BasicTerminal
    attr_reader :done_actions
    def initialize config
      @done_actions = []
    end

    def window cwd, cmd
      if cmd.nil? 
        @done_actions.push(:window, cwd)
      else
        @done_actions.push(:window, cwd, cmd)
      end
    end

    def tab cwd, cmd
      if cmd.nil? 
        @done_actions.push(:tab, cwd)
      else
        @done_actions.push(:tab, cwd, cmd)
      end
    end

    def vsplit cwd, cmd
      if cmd.nil? 
        @done_actions.push(:vsplit, cwd)
      else
        @done_actions.push(:vsplit, cwd, cmd)
      end
    end

    def hsplit cwd, cmd
      if cmd.nil? 
        @done_actions.push(:hsplit, cwd)
      else
        @done_actions.push(:hsplit, cwd, cmd)
      end
    end
  end
end
