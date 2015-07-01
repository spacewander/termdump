require 'minitest/autorun'

require 'termdump/terminal/gnome_terminal'

class TestGnomeTerminal < MiniTest::Test
  @@term = TermDump::Terminal.new({})

  def test_get_configure_key
    nonexist = @@term.get_configure_key 'nonexist'
    assert_nil nonexist
    # in travi ci, since gconftool does not exist, all key will get empty result
  end
end
