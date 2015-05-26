require 'minitest/autorun'
require 'yaml'

require 'termdump'

class TestCommand < MiniTest::Test
  def setup
    @comm = TermDump::Command.new([])
  end

  def get_parsed_args args
    TermDump::Command.new(args.split).instance_variable_get(:@args)
  end

  def test_args
    # list all sessions
    args = get_parsed_args "termdump -l"
    assert_equal true, args.list
    # delete one session
    args = get_parsed_args "termdump -d ruby"
    assert false, args.list
    assert_equal :delete, args.action
    assert_equal 'ruby', args.session
    # list all sessions and delete one
    args = get_parsed_args "termdump -d"
    assert_equal :delete, args.action
    assert_equal true, args.list
    # load one session
    args = get_parsed_args "termdump ruby"
    assert_equal :load, args.action
    assert_equal 'ruby', args.session
    # edit one session
    args = get_parsed_args "termdump -e ruby"
    assert_equal :edit, args.action
    assert_equal 'ruby', args.session
    # dump to a session
    args = get_parsed_args "termdump -s"
    assert_equal :save, args.action
    assert_equal '', args.session
    args = get_parsed_args "TermDump -s ruby"
    assert_equal 'ruby', args.session
    # print result to stdout(works with -s)
    args = get_parsed_args "termdump -s ruby -o"
    assert_equal true, args.stdout
  end

  def test_path
    prefix = @comm.exact_commom_prefix(['~/termdump/bin', '~/termdump/lib', 
                               '~/termdump/test', '~'])
    assert_equal "~/termdump", prefix
    prefix = @comm.exact_commom_prefix(['~', '/root', '/root/some'])
    assert_equal "/root", prefix
    prefix = @comm.exact_commom_prefix(['~/github/bin', '~/termdump/bin'])
    assert_equal "", prefix
    prefix = @comm.exact_commom_prefix(['~/github/bin', '~/termdump/bin', 
                                        '~/termdump/some'])
    assert_equal "", prefix
  end

  def test_dump
    ptree = {
      '1000' => {
        '1234' => ['~/termdump', TermDump::Process.new('1235', '1234', 'S+', 'vim')],
        '2468' => ['~/github']
      },
      '1111' => {
        '2345' => ['~/termdump', TermDump::Process.new('2346', '2345', 'S+', 'pry')]
      }
    }
    path_prefix = {'$HOME' => '~'}
    expected = { '$HOME' => '~',
      'window0' => {
        'tab0' => {
          'cwd' => '~/termdump',
          'command' => 'vim'
        },
        'tab1' => {
          'cwd' => '~/github'
        }
      },
      'window1' => {
        'tab0' => {
          'cwd' => '~/termdump',
          'command' => 'pry'
        }
      }
    }
    assert_equal expected, YAML.load(@comm.dump(ptree, path_prefix))
  end
end
