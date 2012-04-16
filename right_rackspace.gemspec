# -*- encoding: utf-8 -*-

require File.expand_path(File.join(File.dirname(__FILE__), "lib", "right_rackspace", "version"))

Gem::Specification.new do |gem|
  gem.authors       = ["RightScale, Inc."]
  gem.email         = ["support@rightscale.com"]
  gem.description   = %q{RightScale Rackspace Ruby Gem}
  gem.summary       = %q{Interface classes for the Rackspace Services}
  gem.homepage      = "http://rightscale.com"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "right_rackspace"
  gem.require_paths = ["lib"]
  gem.version       = RightScale::Rackspace::VERSION

  gem.add_dependency("right_http_connection", ">= 1.2.1")
end
