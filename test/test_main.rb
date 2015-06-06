require 'minitest/autorun'
require 'yaml'

require 'termdump/main'

class TestCommand < MiniTest::Test
  def setup
    @main = TermDump::Main.new
  end

  def test_read_configure
    config = {'terminal' => 'mock', 'new_window' => 'ctrl+n' }
    IO.write "config_fixture", YAML.dump(config)
    TermDump::Main.class_variable_set :@@config_file, "config_fixture"
    main = TermDump::Main.new
    assert_equal config, main.instance_variable_get(:@config)
    File.delete "config_fixture"
  end

  def test_session_actions
    Dir.rmdir("tmp") if Dir.exist?("tmp")
    Dir.mkdir "tmp"
    path = File.join Dir.pwd, "tmp"
    TermDump::Main.class_variable_set :@@session_dir, path
    status = @main.search_session 'nonexistent'
    assert_equal File.join(path, 'nonexistent.yml'), status[:name]
    assert_equal false, status[:exist]

    @main.save 'termdump', true, false # print to stdout
    assert_equal 2, Dir.entries(path).size
    # print to stdout and exclude current ptty
    # The output is the same as above, as the parent of `rake test` is `rake`
    # but not the session leader
    @main.save 'termdump', true, true 

    @main.save 'termdump', false, false
    assert_equal 3, Dir.entries(path).size
    status = @main.search_session 'termdump'
    assert_equal true, status[:exist]

    # edit_session can't be tested automatically
    res = @main.load_file 'termdump'
    assert_equal true, res.is_a?(Hash)

    task = @main.check res # the output of res may be modified
    assert_equal true, task.is_a?(Hash)

    @main.delete_session 'termdump'
    assert_equal 2, Dir.entries(path).size
    Dir.rmdir "tmp"
  end

  def test_path
    prefix = @main.exact_commom_prefix(['~/termdump/bin', '~/termdump/lib', 
                               '~/termdump/test', '~'])
    assert_equal "~/termdump", prefix
    prefix = @main.exact_commom_prefix(['~', '/root', '/root/some'])
    assert_equal "/root", prefix
    prefix = @main.exact_commom_prefix(['~/github/bin', '~/termdump/bin'])
    assert_equal "", prefix
    prefix = @main.exact_commom_prefix(['~/github/bin', '~/termdump/bin', 
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
        'cwd' => '~/termdump',
        'command' => 'vim',
        'tab0' => {
          'cwd' => '~/github'
        }
      },
      'window1' => {
        'cwd' => '~/termdump',
        'command' => 'pry'
      }
    }
    assert_equal expected, YAML.load(@main.dump(ptree, path_prefix))
  end

  def test_parse_variables
    ptree = { 
      '$HOME' => '~',
      'window0' => {
        'cwd' => '~/${HOME}',
        'tab0' => {
          'cwd' => '${HOME}/termdump',
          'command' => 'vim'
        }
      }
    }
    expected = {
      'window0' => {
        'cwd' => "#{Dir.home}/~",
        'tab0' => {
          'cwd' => "#{Dir.home}/termdump", 'command' => 'vim'
        }
      }
    }
    assert_equal expected, @main.parse_variables(ptree)

    # multiple variables
    ptree = { 
      '$HOME' => '~',
      '$PROJECT' => 'termdump',
      '$other' => '~/github',
      'window0' => {
        'tab0' => { 'cwd' => '${HOME}/${PROJECT}/bin' },
        'tab1' => { 'cwd' => '${HOME}/${PROJECT}/lib' },
        'tab2' => { 'cwd' => '${other}'}
      }
    }
    expected = {
      'window0' => {
        'tab0' => { 'cwd' => "#{Dir.home}/termdump/bin"},
        'tab1' => { 'cwd' => "#{Dir.home}/termdump/lib"},
        'tab2' => { 'cwd' => "#{Dir.home}/github" }
      }
    }
    assert_equal expected, @main.parse_variables(ptree)

    # escape
    ptree = { 
      '$0' => '~/termdump',
      'window0' => {
        'tab0' => { 'cwd' => '${0}/bin' },
        'tab1' => { 'cwd' => '\${0}/lib' },
      }
    }
    expected = {
      'window0' => {
        'tab0' => { 'cwd' => "#{Dir.home}/termdump/bin"},
        'tab1' => { 'cwd' => '\${0}/lib'},
      }
    }
    assert_equal expected, @main.parse_variables(ptree)
  end

  def test_check_node
    node = {
      'cwd' => Dir.home,
      'window0' => { 'cwd' => Dir.home},
      'tab0' => {
        'tab0' => {
          'vsplit' => {
            'hsplit' => {},
            'cwd' => Dir.home,
            'tab0' => {}
          },
          'hsplit' => {}
        }
      }
    }
    expected =  {
      'cwd' => Dir.home,
      "tab0" => {
        'cwd' => Dir.home,
        "tab0" => {
          "vsplit" => {
            "hsplit" => {"cwd"=>Dir.home}, 
            "cwd" => Dir.home
          }, 
          "hsplit" => {"cwd"=>Dir.home},
          'cwd' => Dir.home
        }
      }
    }
    assert_equal expected, @main.check_node(node, :tab)
  end

  def test_cwd_not_exists
    node = {
      'tab' => {'cwd' => '.'}
    }
    # 'cwd' not found in window
    assert_raises TermDump::SessionSyntaxError do
      @main.check_node node, :window
    end
    # use parent's working directory
    @main.check_node node, :window, Dir.home
    assert_equal Dir.home, node['cwd']
  end

  def test_can_not_cd_to
    node = {'cwd' => Dir.home}
    @main.check_node node, :window
    pwd = Dir.pwd
    node = {'cwd' => pwd}
    @main.check_node node, :window
    # can't cd to
    assert_raises TermDump::SessionSyntaxError do
      @main.check_node({'cwd' => 'foo'}, :window, pwd)
    end
  end

  def test_support_relative_path
    node = {'cwd' => '.'}
    pwd = Dir.pwd
    @main.check_node node, :window, pwd
    assert_equal pwd, node['cwd']
    node = {'cwd' => '.'}
    # missing base working directory
    assert_raises TermDump::SessionSyntaxError do
      @main.check_node node, :window
    end
  end

  def test_node_should_be_hash
    node = { 'tab' => 'cwd' }
    # tab should be a node
    assert_raises TermDump::SessionSyntaxError do
      @main.check_node node, :window
    end
  end

  def test_cwd_should_be_string
    node = {'cwd' => {}}
    assert_raises TermDump::SessionSyntaxError do
      @main.check_node node, :window
    end
  end

  def test_command_should_be_string
    node = {'cwd' => Dir.home, 'command' => {}}
    assert_raises TermDump::SessionSyntaxError do
      @main.check_node node, :window
    end
  end

end
