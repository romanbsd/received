# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "received/version"

Gem::Specification.new do |s|
  s.name        = "received"
  s.version     = Received::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Roman Shterenzon"]
  s.email       = ["romanbsd@yahoo.com"]
  s.homepage    = ""
  s.summary     = %q{Receive mail from Postfix and store it somewhere}
  s.description = %q{Currently stores received mail in MongoDB}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'daemons'
  s.add_runtime_dependency 'eventmachine'
  s.add_runtime_dependency 'mongo', '~>1.3.0'
  s.add_runtime_dependency 'bson_ext', '~>1.3.0'
end
