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

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'contained_mr'

class MiniTest::Test
end

File.unlink 'testdata/hello.zip' if File.file?('testdata/hello.zip')
Zip::File.open('testdata/hello.zip', Zip::File::CREATE) do |zip|
  files = Dir.chdir('testdata/hello') { Dir.glob('**/*') }.sort
  files.each do |file|
    path = File.join 'testdata/hello', file
    next unless File.file?(path)
    zip.add file, path
  end
end

MiniTest.autorun
