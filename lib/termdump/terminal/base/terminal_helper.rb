require 'shellwords'

module TermDump
  module TerminalHelper

    # Doing convertion below and join them with '+'
    # case 0 : <Ctrl><Shift><Alt><Super> => Ctrl Shift Alt Super
    # case 1 : [A-Z] => [a-z]
    # case 2 : <Primary> => Ctrl
    # case 3 : [0-9] [a-z] UpDownLeftRight F[0-12] Return space... => not changed
    # For example, 
    # '<Primary><Shift>A' => 'Ctrl+Shift+a'
    # '<Alt>space' => 'Alt+space'
    def convert_key_sequence in_sequence
      in_sequence.tr_s!('[<>]', ' ')
      out_sequence = in_sequence.split.map do |key|
        if /^[[:upper:]]$/.match(key)
          key.downcase
        elsif key == 'Primary'
          'Ctrl'
        else
          key
        end
      end
      out_sequence.join('+')
    end
    
    # escape the command string so that it can be executed safily in the shell
    def escape cmd
      # not woking under windows, but I don't think I will support windows :)
      Shellwords.escape cmd
    end

  end
end
