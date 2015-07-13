$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "termdump/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'termdump'
  s.version     = TermDump::VERSION
  s.authors     = ["spacewander"]
  s.email       = ["spacewanderlzx@gmail.com"]
  s.homepage    = 'https://github.com/spacewander/termdump'
  s.summary     = 'Dump your (pseudo)terminal session and replay it'
  s.description = 'Dump your (pseudo)terminal session and replay it'
  s.files       = Dir["lib/**/*"] + Dir["etc/*"] + ["README.md", "Rakefile"]
  s.test_files  = Dir["test/*"]
  s.extensions = ['etc/Rakefile']
  s.post_install_message = <<-EOS
You can get a bash completion script from [https://github.com/spacewander/termdump/blob/master/etc/termdump]
and a zsh completion script from [https://github.com/spacewander/termdump/blob/master/etc/_termdump]
  EOS
  s.executables << 'termdump'
  s.license     = 'MIT'
  s.required_ruby_version = '>= 1.9'
end

