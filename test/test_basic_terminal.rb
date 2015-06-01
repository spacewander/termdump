require 'minitest/autorun'

require 'termdump/terminal/base'

class TestBasicTerminal < MiniTest::Test
  def test_configure
    @basic_terminal = TermDump::BasicTerminal.new({'new_window' => 'ctrl+n'})
    assert_raises KeyError do
      @basic_terminal.configure 'new_tab'
    end
    assert_equal 'ctrl+n', @basic_terminal.configure('new_window')
  end
end
