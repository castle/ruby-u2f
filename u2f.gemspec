$:.push File.expand_path("../lib", __FILE__)

require 'version'

Gem::Specification.new do |s|
  s.name        = 'u2f'
  s.version     = U2F::VERSION
  s.summary     = 'U2F library'
  s.description = 'Library for handling registration and authentication of U2F devices'
  s.authors     = ['Johan Brissmyr', 'Sebastian Wallin']
  s.email       = ['brissmyr@gmail.com', 'sebastian.wallin@gmail.com']
  s.homepage    = 'https://github.com/userbin/ruby-u2f'
  s.license     = 'MIT'

  s.files       = Dir['{lib}/**/*'] + ['README.md']
  s.test_files  = Dir['spec/**/*']

  s.add_development_dependency 'rake', '~> 10.3.2'
  s.add_development_dependency 'rspec', '~> 3.1.0'
  s.add_development_dependency 'json_expressions', '~> 0.8.3'
  s.add_development_dependency 'rubocop', '~> 0.27.0'
  s.add_development_dependency 'coveralls', '~> 0.7.1'
  s.add_development_dependency 'simplecov', '~> 0.9.1'
end
