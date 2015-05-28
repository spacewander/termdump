require 'termdump/terminal'

module TermDump
  Action = Struct.new(:type, :content)

  class Session
    def initialize terminal_type = nil
      @terminal = Terminal.new
      @action_queue = []
      @support_split = Terminal.public_method_defined?(:vsplit) && 
        Terminal.public_method_defined?(:hsplit)
      @support_tab = Terminal.public_method_defined?(:tab)
      @cwd = '~'
    end

    def replay task
      p task
      scan task
      fallback
      exec
    end

    def scan node
      node.each_pair do |k, v|
        if k == 'command'
          @action_queue.push(Action.new(:command, v))
        elsif k == 'cwd'
          @action_queue.push(Action.new(:cwd, v))
        elsif k.start_with?('tab')
          @action_queue.push(Action.new(:tab, k))
        elsif k.start_with?('vsplit')
          @action_queue.push(Action.new(:vsplit, k))
        elsif k.start_with?('hsplit')
          @action_queue.push(Action.new(:hsplit, k))
        elsif k.start_with?('window')
          @action_queue.push(Action.new(:window, k))
        end
        scan v if v.is_a?(Hash)
      end
    end

    def fallback
      unless @support_split
        @action_queue.each_index do |i|
          if @action_queue[i].type == :vsplit || @action_queue[i].type == :hsplit
            @action_queue[i].type = :tab
          end
        end
      end
      unless @support_tab
        @action_queue.each_index { |i|
          @action_queue[i].type = :window if @action_queue[i].type == :tab }
      end
    end

    def exec
      terminal = nil
      @action_queue.each do |action|
        case action.type
        when :command
          terminal.exec action.content
        when :cwd
          if action.content != @cwd
            terminal.exec "cd #{action.content}"
            @cwd = action.content
          end
        when :window
          terminal = @terminal.new_window
        when :tab
          terminal.tab action.content
        when :vsplit
          terminal.vsplit action.content
        when :hsplit
          terminal.hsplit action.content
        end
      end
    end
  end

end
