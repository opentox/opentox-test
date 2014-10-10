# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = "opentox-test"
  gem.version     = File.read("./VERSION")
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
  gem.required_ruby_version = '>= 1.9.2'

  gem.add_runtime_dependency 'minitest'
  gem.add_runtime_dependency "opentox-client"
  gem.add_runtime_dependency 'capybara'#, "= 2.1.0"
  gem.add_runtime_dependency 'capybara-webkit'#, "= 1.0.0"
  gem.post_install_message = "Please configure test in ~/.opentox/config/test.rb"

end
