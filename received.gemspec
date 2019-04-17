# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "received/version"

Gem::Specification.new do |s|
  s.name        = "received"
  s.version     = Received::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Roman Shterenzon"]
  s.email       = ["romanbsd@yahoo.com"]
  s.homepage    = "https://github.com/romanbsd/received"
  s.license     = "MIT"
  s.summary     = %q{Receive mail from Postfix and store it somewhere}
  s.description = %q{Currently stores received mail in MongoDB or Redis}

  s.files         = Dir["lib/**/*", "*.gemspec", "LICENSE*", "README*"]
  s.executables   = Dir["bin/*"].map { |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_runtime_dependency 'daemons', '~> 1.1'
  s.add_runtime_dependency 'eventmachine', '~> 1.0'
  s.add_runtime_dependency 'mongo', '~> 1.3'
  s.add_runtime_dependency 'bson_ext', '~> 1.3'
  s.add_runtime_dependency 'redis', '~> 4.1'
  s.add_runtime_dependency 'charlock_holmes', '~> 0.7'
end
