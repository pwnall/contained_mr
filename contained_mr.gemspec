# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: contained_mr 0.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "contained_mr"
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Victor Costan"]
  s.date = "2015-10-09"
  s.description = "Plumbing for running mappers and reducers inside Docker containers"
  s.email = "victor@costan.us"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = [
    ".document",
    ".travis.yml",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE",
    "README.md",
    "Rakefile",
    "VERSION",
    "contained_mr.gemspec",
    "lib/contained_mr.rb",
    "lib/contained_mr/cleaner.rb",
    "lib/contained_mr/job.rb",
    "lib/contained_mr/job_logic.rb",
    "lib/contained_mr/mock.rb",
    "lib/contained_mr/mock/job.rb",
    "lib/contained_mr/mock/runner.rb",
    "lib/contained_mr/mock/template.rb",
    "lib/contained_mr/namespace.rb",
    "lib/contained_mr/runner.rb",
    "lib/contained_mr/runner_logic.rb",
    "lib/contained_mr/template.rb",
    "lib/contained_mr/template_logic.rb",
    "test/concerns/job_state_cases.rb",
    "test/helper.rb",
    "test/test_cleaner.rb",
    "test/test_contained_mr.rb",
    "test/test_job.rb",
    "test/test_job_logic.rb",
    "test/test_mock_job.rb",
    "test/test_mock_runner.rb",
    "test/test_mock_template.rb",
    "test/test_runner.rb",
    "test/test_runner_logic.rb",
    "test/test_template.rb",
    "test/test_template_logic.rb",
    "testdata/Dockerfile.hello.mapper",
    "testdata/Dockerfile.hello.reducer",
    "testdata/hello/Dockerfile",
    "testdata/hello/data/goodbye.txt",
    "testdata/hello/data/hello.txt",
    "testdata/hello/mapper.sh",
    "testdata/hello/mapreduced.yml",
    "testdata/hello/reducer.sh",
    "testdata/input.hello",
    "testdata/job.hello"
  ]
  s.homepage = "http://github.com/pwnall/contained_mr"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.5.1"
  s.summary = "Map-Reduce with Docker containers"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<docker-api>, [">= 1.22.4"])
      s.add_runtime_dependency(%q<rubyzip>, [">= 1.1.7"])
      s.add_development_dependency(%q<bundler>, [">= 1.6.1"])
      s.add_development_dependency(%q<jeweler>, [">= 2.0.1"])
      s.add_development_dependency(%q<minitest>, [">= 5.8.0"])
      s.add_development_dependency(%q<mocha>, [">= 1.1.0"])
      s.add_development_dependency(%q<rdoc>, [">= 4.2.0"])
      s.add_development_dependency(%q<simplecov>, [">= 0.10.0"])
      s.add_development_dependency(%q<yard>, [">= 0.8.7.6"])
    else
      s.add_dependency(%q<docker-api>, [">= 1.22.4"])
      s.add_dependency(%q<rubyzip>, [">= 1.1.7"])
      s.add_dependency(%q<bundler>, [">= 1.6.1"])
      s.add_dependency(%q<jeweler>, [">= 2.0.1"])
      s.add_dependency(%q<minitest>, [">= 5.8.0"])
      s.add_dependency(%q<mocha>, [">= 1.1.0"])
      s.add_dependency(%q<rdoc>, [">= 4.2.0"])
      s.add_dependency(%q<simplecov>, [">= 0.10.0"])
      s.add_dependency(%q<yard>, [">= 0.8.7.6"])
    end
  else
    s.add_dependency(%q<docker-api>, [">= 1.22.4"])
    s.add_dependency(%q<rubyzip>, [">= 1.1.7"])
    s.add_dependency(%q<bundler>, [">= 1.6.1"])
    s.add_dependency(%q<jeweler>, [">= 2.0.1"])
    s.add_dependency(%q<minitest>, [">= 5.8.0"])
    s.add_dependency(%q<mocha>, [">= 1.1.0"])
    s.add_dependency(%q<rdoc>, [">= 4.2.0"])
    s.add_dependency(%q<simplecov>, [">= 0.10.0"])
    s.add_dependency(%q<yard>, [">= 0.8.7.6"])
  end
end

