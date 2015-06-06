require 'minitest/autorun'

require 'termdump/command'

class TestCommand < MiniTest::Test
  def setup
    @comm = TermDump::Command.new([])
  end

  def get_parsed_args args
    TermDump::Command.new(args.split).instance_variable_get(:@args)
  end

  def test_args
    # list all sessions
    args = get_parsed_args "-l"
    assert_equal true, args.list
    args = get_parsed_args ""
    assert_equal :load, args.action
    assert_equal true, args.list
    # delete one session
    args = get_parsed_args "-d ruby"
    assert_equal false, args.list
    assert_equal :delete, args.action
    assert_equal 'ruby', args.session
    # list all sessions and delete one
    args = get_parsed_args "-d"
    assert_equal :delete, args.action
    assert_equal true, args.list
    # load one session
    args = get_parsed_args "ruby"
    assert_equal :load, args.action
    assert_equal 'ruby', args.session
    assert_equal false, args.list
    # edit one session
    args = get_parsed_args "-e ruby"
    assert_equal :edit, args.action
    assert_equal 'ruby', args.session
    # dump to a session
    args = get_parsed_args "-s"
    assert_equal :save, args.action
    assert_equal true, args.list
    args = get_parsed_args "-s ruby"
    assert_equal 'ruby', args.session
    # print result to stdout(works with -s)
    args = get_parsed_args "-s ruby --stdout"
    assert_equal true, args.stdout
    # initialize interactively
    args = get_parsed_args "-i"
    assert_equal :init, args.action
  end
end
