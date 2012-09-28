# -*- encoding: utf-8 -*-
require File.expand_path('../lib/ofx-parser/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Andrew A. Smith"]
  gem.email         = ["andy@tinnedfruit.org"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{ofx-parser is a ruby library for parsing OFX 1.x data.}
  gem.homepage      = "http://ofx-parser.rubyforge.org/"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "ofx-parser"
  gem.require_paths = ["lib"]
  gem.add_dependency("hpricot",">= 0.6")
  gem.version       = OfxParser::VERSION
end
