require 'minitest/autorun'

require 'termdump/terminal/tilda'

class TestTerminator < MiniTest::Test
  @@term = TermDump::Terminal.new({})

  def test_parse_configure
    lines = [
      'addtab_key = "<Primary><Shift>x"',
      '#fullscreen_key = "F11"',
    ]
    config = @@term.parse_configure lines
    assert_equal 'Ctrl+Shift+x', config['new_tab']

    lines = ['addtab_key="<Control>x" # "x"']
    config = @@term.parse_configure lines
    assert_equal 'Ctrl+x', config['new_tab']
  end
end

