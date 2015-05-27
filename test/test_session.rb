require 'minitest/autorun'

require 'termdump/session'

class TestSession < MiniTest::Test
  def setup
    @session = TermDump::Session.new
  end

  def inject_action_queue actions
    @session.instance_variable_set(:@action_queue, actions)
  end

  def test_fallback_not_support_tab
    @session.instance_variable_set(:@support_tab, false)
    @session.instance_variable_set(:@support_split, true)
    actions = [
      TermDump::Action.new(:window, 'window0'),
      TermDump::Action.new(:tab, 'tab0'),
      TermDump::Action.new(:tab, 'tab1'),
      TermDump::Action.new(:window, 'window1')
    ]
    inject_action_queue actions
    @session.fallback
    expected = [
      TermDump::Action.new(:window, 'window0'),
      TermDump::Action.new(:window, 'tab0'),
      TermDump::Action.new(:window, 'tab1'),
      TermDump::Action.new(:window, 'window1')
    ]
    assert_equal expected, @session.instance_variable_get(:@action_queue)
  end

  def test_fallback_not_support_split
    @session.instance_variable_set(:@support_tab, true)
    @session.instance_variable_set(:@support_split, false)
    actions = [
      TermDump::Action.new(:window, 'window0'),
      TermDump::Action.new(:tab, 'tab0'),
      TermDump::Action.new(:split, 'split0'),
      TermDump::Action.new(:split, 'split1')
    ]
    inject_action_queue actions
    @session.fallback
    expected = [
      TermDump::Action.new(:window, 'window0'),
      TermDump::Action.new(:tab, 'tab0'),
      TermDump::Action.new(:tab, 'split0'),
      TermDump::Action.new(:tab, 'split1')
    ]
    assert_equal expected, @session.instance_variable_get(:@action_queue)
  end
end
