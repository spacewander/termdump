require 'ostruct'
require 'optparse'

require 'termdump/main'
require 'termdump/version'

module TermDump
  class Command
    def initialize args
      @args = OpenStruct.new(:stdout => false, :action => :load, :list => false,
                             :session => '', :exclude => false)
      OptionParser.new do |opts|
        opts.banner = "Usage: termdump [options] [session]"
        opts.on('-i', '--init', 'initialize configure interactively') {
          @args.action = :init
        }
        opts.on('-e', '--edit [session]', 'edit session') do |name|
          @args.action = :edit
          name.nil? ? @args.list = true : @args.session = name
        end
        opts.on('-d', '--delete [session]', 'delete session') do |name|
          @args.action = :delete
          name.nil? ? @args.list = true : @args.session = name
        end
        opts.on('-s', '--save [session]', 'save session') do |name|
          @args.action = :save
          name.nil? ? @args.list = true : @args.session = name
        end

        opts.on_tail('--stdout', 'print dump result to stdout while saving a session') {
          @args.stdout = true 
        }
        opts.on_tail('--exclude', 'exclude current pty while saving a session') {
          @args.exclude = true
        }
        opts.on_tail('-l', '--list', 'list all sessions') { 
          @args.list = true
        }
        opts.on_tail('-v', '--version', 'print version') do
          puts VERSION
          exit 0
        end
        begin
          opts.parse! args
        rescue OptionParser::InvalidOption
          puts opts.help
          exit 1
        end

        # :load is the default action if no option given
        if @args.action == :load
          args.size > 0 ? @args.session = args[0] : @args.list = true
        end
        # --stdout should be used with --save
        if @args.stdout || @args.exclude
          if @args.action != :save
            puts opts.help 
            exit 1
          end
        end
      end
    end

    def run
      main = Main.new
      if @args.action == :save
        main.save @args.session, @args.stdout, @args.exclude
      elsif @args.action == :init
        main.init
      elsif @args.list
        main.list @args.action
      else
        name = @args.session
        case @args.action
        when :delete
          main.delete_session name
        when :edit
          main.edit_session name
        when :load
          main.load_session name
        end
      end
    end
     
  end
end
