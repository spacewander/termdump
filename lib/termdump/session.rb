module TermDump
  Node = Struct.new(:type, :cwd, :command)

  class Session
    # Optional Configures:
    # * terminal: The type of terminal
    # * new_window: The key sequence used to open a new window
    # * new_tab: The key sequence used to open a new tab
    # * new_vsplit: The key sequence used to open a new vsplit
    # * new_hsplit: The key sequence used to open a new hsplit
    def initialize config={}
      if config.has_key?('terminal')
        begin
          terminal = config['terminal']
          require_relative "terminal/#{terminal}"
        rescue LoadError
          puts "Load with terminal #{terminal} error:"
          puts "Not support #{terminal} yet!"
          exit 0
        end
      else
        require_relative "terminal/default"
      end
      @terminal = Terminal.new(config)
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
