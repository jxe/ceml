# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ceml}
  s.version = "0.8.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Joe Edelman"]
  s.date = %q{2011-05-27}
  s.description = %q{a language for coordinating real world events}
  s.email = %q{joe@citizenlogistics.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.markdown"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "Makefile",
     "README.markdown",
     "Rakefile",
     "VERSION",
     "ceml.gemspec",
     "editors/CEML.tmbundle/Syntaxes/ceml.tmLanguage",
     "editors/CEML.tmbundle/info.plist",
     "examples/breakfast-exchange.ceml",
     "examples/citizen-investigation.ceml",
     "examples/high-fives.ceml",
     "guide/guide.html",
     "guide/guide.md",
     "guide/guide.pdf",
     "lib/ceml.rb",
     "lib/ceml/driver.rb",
     "test/helper.rb",
     "test/test_incident.rb",
     "try"
  ]
  s.homepage = %q{http://github.com/citizenlogistics/ceml}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{a language for coordinating real world events}
  s.test_files = [
    "test/helper.rb",
     "test/lang/test_casting.rb",
     "test/lang/test_instructions.rb",
     "test/lang/test_scripts.rb",
     "test/test_basic_seed.rb",
     "test/test_castable.rb",
     "test/test_dialogues.rb",
     "test/test_incident.rb"
  ]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<treetop>, [">= 0"])
    else
      s.add_dependency(%q<treetop>, [">= 0"])
    end
  else
    s.add_dependency(%q<treetop>, [">= 0"])
  end
end

