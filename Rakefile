require 'bundler/setup'
require 'rake/testtask'

Rake::TestTask.new do |t|
  args = ARGV[1..-1]
  globs =
    if args.empty?
      ["test/**/*_test.rb"]
    else
      args.map { |x|
        if Dir.exists? x
          "#{x}/**/*_test.rb"
        elsif File.exists? x
          x
        end
      }.compact
    end

  t.libs << 'lib' << 'test'
  t.test_files = FileList[*globs]
  t.verbose = false
end
