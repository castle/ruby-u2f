# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('../lib', __FILE__)

require 'u2f/version'

Gem::Specification.new do |s|
  s.name        = 'u2f'
  s.version     = U2F::VERSION
  s.summary     = 'U2F library'
  s.description = 'Library for handling registration and authentication of U2F devices'
  s.authors     = ['Johan Brissmyr', 'Sebastian Wallin']
  s.email       = ['brissmyr@gmail.com', 'sebastian.wallin@gmail.com']
  s.homepage    = 'https://github.com/castle/ruby-u2f'
  s.license     = 'MIT'
  s.required_ruby_version = '>= 2.3'

  s.files       = Dir['{lib}/**/*'] + ['README.md', 'LICENSE']
  s.test_files  = Dir['spec/**/*']
end
