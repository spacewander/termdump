require 'minitest/autorun'

require 'termdump/terminal/base/base'

class TestBasicTerminal < MiniTest::Test
  def test_configure
    bt = TermDump::BasicTerminal.new({'new_window' => 'ctrl+n'})
    assert_raises KeyError do
      bt.configure 'new_tab'
    end
    assert_equal 'ctrl+n', bt.configure('new_window')
  end

  def test_convert_key_sequence
    bt = TermDump::BasicTerminal.new({})
    assert_equal 'Ctrl+a+Shift', bt.convert_key_sequence('<Ctrl>A<Shift>')
    assert_equal 'Ctrl+Shift+a', bt.convert_key_sequence('<Primary><Shift>A')
    assert_equal 'Alt+space', bt.convert_key_sequence('<Alt>space')
    assert_equal 'Super+plus', bt.convert_key_sequence('<Super>plus')
    assert_equal 'a', bt.convert_key_sequence('A')
    assert_equal 'Shift+a', bt.convert_key_sequence('<Shift>A')
  end 

  def test_escape
    bt = TermDump::BasicTerminal.new({})
    res = IO.popen("echo #{bt.escape("com && this")}").read.chomp
    assert_equal "com && this", res
    res = IO.popen("echo #{bt.escape("com || this")}").read.chomp
    assert_equal "com || this", res
  end

end
