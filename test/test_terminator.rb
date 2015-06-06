require 'minitest/autorun'

require 'termdump/terminal/terminator'

class TestTerminator < MiniTest::Test
  ENV['XDG_CONFIG_HOME'] = 'nonexist' # test configure not found
  @@term = TermDump::Terminal.new({})

  def test_convert_key_sequence
    assert_equal 'Ctrl+a+Shift', @@term.convert_key_sequence('<Ctrl>A<Shift>')
    assert_equal 'Ctrl+Shift+a', @@term.convert_key_sequence('<Primary><Shift>A')
    assert_equal 'Alt+space', @@term.convert_key_sequence('<Alt>space')
    assert_equal 'Super+plus', @@term.convert_key_sequence('<Super>plus')
    assert_equal 'a', @@term.convert_key_sequence('A')
    assert_equal 'Shift+a', @@term.convert_key_sequence('<Shift>A')
  end 

  def test_parse_configure
    lines = [
      '[global_config]',
      '[keybindings]',
      '  full_screen = <Ctrl><Shift>F11',
      '  new_tab = <Alt>Up # new tab',
      '  split_vert = <Alt>V',
      '  split_horiz = <Alt># # split horizontally',
      '  zoom_in = <Primary>equal',
      '  prev_tab = <Alt>Left']
    config = @@term.parse_configure lines
    expected = {
      'new_tab' => 'Alt+Up',
      'new_vsplit' => 'Alt+v',
      'new_hsplit' => 'Alt+#'
    }
    assert_equal expected, config
  end
end
