require 'rubygems'
require 'hoe'
$:.unshift(File.dirname(__FILE__) + "/lib")
require 'ofx-parser'

Hoe.plugin :gemspec
Hoe.spec('ofx-parser') do |p|
  p.author = 'Andrew A. Smith'
  p.email = 'andy@tinnedfruit.org'
  p.summary = 'ofx-parser is a ruby library for parsing OFX 1.x data.'
  p.description = p.paragraphs_of('README.txt', 2..5).join("\n\n")
  p.urls = ['http://ofx-parser.rubyforge.org/']
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.extra_deps << ["hpricot", ">= 0.6"]
  p.need_zip = true
  p.need_tar = false
  p.version = OfxParser::VERSION
end
