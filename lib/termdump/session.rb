require 'termdump/terminal'

module TermDump
  Node = Struct.new(:type, :cwd, :command)

  class Session
    def initialize terminal_type = nil
      @terminal = Terminal.new
      @node_queue = []
      @support_split = Terminal.public_method_defined?(:vsplit) && 
        Terminal.public_method_defined?(:hsplit)
      @support_tab = Terminal.public_method_defined?(:tab)
    end

    def replay task
      scan task
      fallback
      exec
    end

    def enqueue type, attributes
      @node_queue.push(Node.new(type, attributes['cwd'], attributes['command']))
    end

    def scan node
      node.each_pair do |k, v|
        if k.start_with?('tab')
          enqueue :tab, v
        elsif k.start_with?('vsplit')
          enqueue :vsplit, v
        elsif k.start_with?('hsplit')
          enqueue :hsplit, v
        elsif k.start_with?('window')
          enqueue :window, v
        end
        scan v if v.is_a?(Hash)
      end
    end

    def fallback
      unless @support_split
        @node_queue.each_index do |i|
          if @node_queue[i].type == :vsplit || @node_queue[i].type == :hsplit
            @node_queue[i].type = :tab
          end
        end
      end
      unless @support_tab
        @node_queue.each_index { |i|
          @node_queue[i].type = :window if @node_queue[i].type == :tab }
      end
    end

    def exec
      @node_queue.each do |node|
        case node.type
        when :window, :tab, :vsplit, :hsplit
          @terminal.method(node.type).call(node.cwd, node.command)
        end
      end
    end
  end

end
