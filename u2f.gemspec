$:.push File.expand_path("../lib", __FILE__)

require 'version'

Gem::Specification.new do |s|
  s.name        = 'u2f'
  s.version     = U2F::VERSION
  s.summary     = 'U2F library'
  s.description = 'U2F library'
  s.authors     = ['Johan Brissmyr', 'Sebastian Wallin']
  s.email       = ['brissmyr@gmail.com', 'sebastian.wallin@gmail.com']
  s.homepage    = 'https://github.com/userbin/ruby-u2f'
  s.license     = 'MIT'

  s.files       = Dir['{lib}/**/*'] + ['README.md']
  s.test_files  = Dir['spec/**/*']

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'json_expressions'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'coveralls'
end
