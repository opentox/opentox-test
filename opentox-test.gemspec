# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = "opentox-test"
  gem.authors       = ["Christoph Helma"]
  gem.email         = ["helma@in-silico.ch"]
  gem.description   = %q{Tests for OpenTox/ToxBank services}
  gem.summary       = %q{Tests for OpenTox/ToxBank services}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "opentox-test"
  gem.require_paths = ["test"]
  gem.version         = "0.0.1pre"

  gem.add_runtime_dependency "opentox-client"

end
