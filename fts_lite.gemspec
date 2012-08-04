# -*- coding: utf-8 -*-
require File.expand_path('../lib/fts_lite/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["nagadomi"]
  gem.email         = ["nagadomi@nurs.or.jp"]
  gem.description   = %q{simple full text search engine}
  gem.summary       = %q{simple full text search engine}
  gem.homepage      = "https://github.com/nagadomi/fts_lite"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "fts_lite"
  gem.require_paths = ["lib"]
  gem.version       = FtsLite::VERSION
  
  gem.add_dependency 'bimyou_segmenter', '>= 1.2.0'
  gem.add_dependency 'sqlite3-ruby'
end
