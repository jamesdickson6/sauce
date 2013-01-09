$:.push File.expand_path("../lib", __FILE__)
require "sauce/version"

Gem::Specification.new do |s|

  s.name        = "sauce"
  s.version     = Sauce::Version.to_s
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["James Dickson"]
  s.email       = ["jdickson@bertramcapital.com"]
  s.homepage    = "http://github.com/sixjameses/sauce"
  s.summary     = "Saucify applications."
  s.description = "This leverages Capistrano, to make managing your application environments and deployments easy."
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.extra_rdoc_files = ["README.md"]

  s.add_dependency('capistrano', '>= 2.13.5')
  #s.add_dependency('highline') #Capistrano dependency
end
