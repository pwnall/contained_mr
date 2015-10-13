require 'simplecov'

module SimpleCov::Configuration
  def clean_filters
    @filters = []
  end
end

SimpleCov.configure do
  clean_filters
  load_profile 'test_frameworks'
end

ENV["COVERAGE"] && SimpleCov.start do
  add_filter "/.rvm/"
end
require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'minitest/autorun'
require 'mocha/mini_test'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'contained_mr'

class MiniTest::Test
end

['hello', 'invalid'].each do |dir|
  File.unlink "testdata/#{dir}.zip" if File.file?("testdata/#{dir}.zip")
  Zip::File.open("testdata/#{dir}.zip", Zip::File::CREATE) do |zip|
    files = Dir.chdir("testdata/#{dir}") { Dir.glob('**/*') }.sort
    files.each do |file|
      path = File.join "testdata/#{dir}", file
      if File.directory? path
        zip.mkdir file
      elsif File.file? path
        zip.add file, path
      end
    end
  end
end
ContainedMr::Cleaner.new('contained_mrtests').destroy_all!

MiniTest.autorun
