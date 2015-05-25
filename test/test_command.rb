require 'minitest/autorun'
require 'yaml'

require 'termdump/command'

class TestCommand < MiniTest::Test
  def setup
    @comm = TermDump::Command.new([])
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
