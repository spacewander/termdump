require 'minitest/autorun'

require 'termdump/session'

class TestSession < MiniTest::Test
  def setup
    @session = TermDump::Session.new({'terminal' => 'base/mock'})
  end

  def inject_node_queue actions
    @session.instance_variable_set(:@node_queue, actions)
  end

  def node_queue
    @session.instance_variable_get(:@node_queue)
  end

  def test_fallback_not_support_tab
    @session.instance_variable_set(:@support_tab, false)
    @session.instance_variable_set(:@support_split, true)
    actions = [
      TermDump::Node.new(:window, 'window', ''),
      TermDump::Node.new(:tab, 'tab', ''),
      TermDump::Node.new(:tab, 'tab', ''),
      TermDump::Node.new(:window, 'window', '')
    ]
    inject_node_queue actions
    @session.fallback
    expected = [
      TermDump::Node.new(:window, 'window', ''),
      TermDump::Node.new(:window, 'tab', ''),
      TermDump::Node.new(:window, 'tab', ''),
      TermDump::Node.new(:window, 'window', '')
    ]
    assert_equal expected, node_queue
  end

  def test_fallback_not_support_split
    @session.instance_variable_set(:@support_tab, true)
    @session.instance_variable_set(:@support_split, false)
    actions = [
      TermDump::Node.new(:window, 'window', ''),
      TermDump::Node.new(:tab, 'tab', ''),
      TermDump::Node.new(:vsplit, 'vsplit', ''),
      TermDump::Node.new(:vsplit, 'vsplit', '')
    ]
    inject_node_queue actions
    @session.fallback
    expected = [
      TermDump::Node.new(:window, 'window', ''),
      TermDump::Node.new(:tab, 'tab', ''),
      TermDump::Node.new(:tab, 'vsplit', ''),
      TermDump::Node.new(:tab, 'vsplit', '')
    ]
    assert_equal expected, node_queue
  end

  def test_scan
    node = {
      'window' => {
        'cwd' => 'home',
        'tab' => {
          'cwd' => 'some',
          'command' => 'rm -rf /'
        },
        'vsplit' => {
          'cwd' => 'any',
          'command' => 'ls',
          'hsplit' => {
            'cwd' => 'else'
          }
        }
      }
    }
    @session.scan node
    expected = [
      TermDump::Node.new(:window, 'window', 'home'),
      TermDump::Node.new(:tab, 'tab', 'some', 'rm -rf /'),
      TermDump::Node.new(:vsplit, 'vsplit', 'any', 'ls'),
      TermDump::Node.new(:hsplit, 'hsplit', 'else')
    ]
    assert_equal expected, node_queue
  end

  def test_replay
    task = {
      'window' => {
        'cwd' => 'home',
        'tab' => {
          'cwd' => 'some',
          'command' => 'rm -rf /'
        },
        'vsplit' => {
          'cwd' => 'any',
          'command' => 'ls',
          'hsplit' => {
            'cwd' => 'else'
          }
        }
      }
    }
    session = TermDump::Session.new({'terminal' => 'base/mock'})
    session.replay(task)
    done_actions = session.instance_variable_get(:@terminal).done_actions
    expected = [
      ['home'],
      [:tab, 'tab', 'some', 'rm -rf /'],
      [:vsplit, 'vsplit', 'any', 'ls'],
      [:hsplit, 'hsplit', 'else']
    ].flatten!
    assert_equal expected, done_actions
  end
end
