# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "ofx-parser"
  s.version = "1.1.0.20121129105223"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Andrew A. Smith"]
  s.date = "2012-11-29"
  s.description = "ofx-parser is a ruby library to parse a realistic subset of the lengthy OFX 1.x specification."
  s.email = "andy@tinnedfruit.org"
  s.files = ["History.md", "LICENSE", "README.md", "Rakefile", "lib/mcc.rb", "lib/ofx-parser.rb", "lib/ofx.rb", "test/fixtures/banking.ofx.sgml", "test/fixtures/creditcard.ofx.sgml", "test/fixtures/list.ofx.sgml", "test/fixtures/malformed_header.ofx.sgml", "test/fixtures/with_spaces.ofx.sgml", "test/test_ofx_parser.rb"]
  s.homepage = "https://github.com/aasmith/ofx-parser"
  s.license = "Copyright (c) 2007, Andrew A. Smith"
  s.rdoc_options = ["--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "ofx-parser is a ruby library for parsing OFX 1.x data."
  s.test_files = ["test/test_ofx_parser.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<hpricot>, [">= 0.6"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.10"])
    else
      s.add_dependency(%q<hpricot>, [">= 0.6"])
      s.add_dependency(%q<rdoc>, ["~> 3.10"])
    end
  else
    s.add_dependency(%q<hpricot>, [">= 0.6"])
    s.add_dependency(%q<rdoc>, ["~> 3.10"])
  end
end
