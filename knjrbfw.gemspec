Gem::Specification.new do |s|
  s.name = "knjrbfw"
  s.version = "0.0.116"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Kasper Stöckel"]
  s.description = "Including stuff for HTTP, SSH and much more."
  s.email = "k@spernj.org"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = Dir["{include,lib}/**/*"] + ["Rakefile"]
  s.homepage = "http://github.com/kaspernj/knjrbfw"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.0"
  s.summary = "A framework with lots of stuff for Ruby."

  s.add_runtime_dependency("wref", ">= 0.0.8")
  s.add_runtime_dependency("tsafe", ">= 0")
  s.add_runtime_dependency("datet", ">= 0")
  s.add_runtime_dependency("http2", ">= 0")
  s.add_runtime_dependency("php4r", ">= 0")
  s.add_runtime_dependency("ruby_process", ">= 0")
  s.add_development_dependency("rspec", ">= 0")
  s.add_development_dependency("bundler", ">= 0")
  s.add_development_dependency("jeweler", ">= 0")
  s.add_development_dependency("sqlite3", ">= 0")
  s.add_development_dependency("rmagick", ">= 0")
  s.add_development_dependency("array_enumerator", ">= 0")
end
