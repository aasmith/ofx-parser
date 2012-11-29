# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "ofx-parser"
  s.version = "1.1.0.20121129105223"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Andrew A. Smith"]
  s.date = "2012-11-29"
  s.description = "== DESCRIPTION:\n\nofx-parser is a ruby library to parse a realistic subset of the lengthy OFX 1.x specification.\n\n== FEATURES/PROBLEMS:\n\n* Reads OFX responses - i.e. those downloaded from financial institutions and\n  puts it into a usable object graph.\n* Supports the 3 main message sets: banking, credit card and investment\n  accounts, as well as the required 'sign on' set.\n* Knows about SIC codes - if your institution provides them.\n  See http://www.eeoc.gov/stats/jobpat/siccodes.html\n* Monetary amounts can be retrieved either as a raw string, or in pennies.\n* Supports OFX timestamps."
  s.email = "andy@tinnedfruit.org"
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "lib/mcc.rb", "lib/ofx-parser.rb", "lib/ofx.rb", "test/fixtures/banking.ofx.sgml", "test/fixtures/creditcard.ofx.sgml", "test/fixtures/list.ofx.sgml", "test/fixtures/malformed_header.ofx.sgml", "test/fixtures/with_spaces.ofx.sgml", "test/test_ofx_parser.rb", ".gemtest"]
  s.homepage = "http://ofx-parser.rubyforge.org/"
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "ofx-parser"
  s.rubygems_version = "1.8.24"
  s.summary = "ofx-parser is a ruby library for parsing OFX 1.x data."
  s.test_files = ["test/test_ofx_parser.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<hpricot>, [">= 0.6"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.10"])
      s.add_development_dependency(%q<hoe>, ["~> 3.3"])
    else
      s.add_dependency(%q<hpricot>, [">= 0.6"])
      s.add_dependency(%q<rdoc>, ["~> 3.10"])
      s.add_dependency(%q<hoe>, ["~> 3.3"])
    end
  else
    s.add_dependency(%q<hpricot>, [">= 0.6"])
    s.add_dependency(%q<rdoc>, ["~> 3.10"])
    s.add_dependency(%q<hoe>, ["~> 3.3"])
  end
end
