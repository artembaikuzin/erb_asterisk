# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'erb_asterisk/version'

Gem::Specification.new do |spec|
  spec.name          = 'erb_asterisk'
  spec.version       = ErbAsterisk::VERSION
  spec.authors       = ['Artem Baikuzin']
  spec.email         = ['ybinzu@gmail.com']

  spec.summary       = 'Asterisk configuration with ERB'
  spec.description   = 'Converts all .erb files to .conf files inside ' \
    'asterisk configuration directory'
  spec.homepage      = 'https://github.com/ybinzu/erb_asterisk'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = 'exe'
  spec.executables   = 'erb_asterisk'
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.10', '>= 5.10.3'
  spec.add_development_dependency 'minitest-reporters', '~> 1.1', '>= 1.1.14'
end
