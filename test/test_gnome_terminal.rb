require 'minitest/autorun'

require 'termdump/terminal/gnome_terminal'

class TestGnomeTerminal < MiniTest::Test
  @@term = TermDump::Terminal.new({})

  def test_add_configure_key
    @@term.add_configure_key 'nonexist'
    config = @@term.instance_variable_get(:@config)
    assert_nil config['nonexist']
    # in travi ci, since gconftool does not exist, all key will get empty result
  end
end
