require_relative 'base'

module TermDump
  class Terminal < BasicTerminal
    attr_reader :done_actions
    def initialize config
      @done_actions = []
    end

    def exec cwd, cmd
      if cmd.nil?
        @done_actions.push(cwd)
      else
        @done_actions.push(cwd, cmd)
      end
    end

    def window name, cwd, cmd
      if cmd.nil? 
        @done_actions.push(:window, name, cwd)
      else
        @done_actions.push(:window, name, cwd, cmd)
      end
    end

    def tab name, cwd, cmd
      if cmd.nil? 
        @done_actions.push(:tab, name, cwd)
      else
        @done_actions.push(:tab, name, cwd, cmd)
      end
    end

    def vsplit name, cwd, cmd
      if cmd.nil? 
        @done_actions.push(:vsplit, name, cwd)
      else
        @done_actions.push(:vsplit, name, cwd, cmd)
      end
    end

    def hsplit name, cwd, cmd
      if cmd.nil? 
        @done_actions.push(:hsplit, name, cwd)
      else
        @done_actions.push(:hsplit, name, cwd, cmd)
      end
    end
  end
end
