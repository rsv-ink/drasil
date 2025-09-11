require 'fileutils'

templates_folder = ARGV[0]

print "Enter gem namespace (ex: my_gem): "
gem_namespace = $stdin.gets.chomp
module_name   = gem_namespace.split('_').map(&:capitalize).join('')

puts "Add parsers folder"
FileUtils.mkdir_p("lib/#{gem_namespace}/parsers")

puts "Add base parser"
source_file_path = File.join(templates_folder, "default_parser.rb")
destination_file_path = "lib/#{gem_namespace}/parsers/default_parser.rb"
FileUtils.copy(source_file_path, destination_file_path)

# Read the contents of the destination file
contents = File.read(destination_file_path)

# Insert the module statement before "class DefaultParser"
module_declaration = "module #{module_name}\n"
contents.gsub!("class DefaultParser", module_declaration + "  class DefaultParser")

# Write the modified contents back to the file
File.open(destination_file_path, "w") { |file| file.write(contents) }

puts "Add resources folder"
FileUtils.mkdir_p("lib/#{gem_namespace}/resources")
source_file_path = File.join(templates_folder, "example.rb")
destination_file_path = "lib/#{gem_namespace}/resources/example.rb"
FileUtils.copy(source_file_path, destination_file_path)

# Read the contents of the destination file
contents = File.read(destination_file_path)

# Insert the module statement before "class Example"
module_declaration = "module #{module_name}\n"
contents.gsub!("class Example", module_declaration + "  class Example")

# Write the modified contents back to the file
File.open(destination_file_path, "w") { |file| file.write(contents) }

puts "Add #{gem_namespace}.rb"
FileUtils.copy(File.join(templates_folder, "gem_name.rb"), "lib/#{gem_namespace}.rb")

puts "Add spec folder"
FileUtils.mkdir_p("spec/#{gem_namespace}")

puts "Add spec_helper.rb"
FileUtils.copy(File.join(templates_folder, "spec_helper.rb"), "spec/spec_helper.rb")

# Add require "gem_namespace" to spec_helper.rb
# Read the contents of the destination file
destination_file_path = "spec/spec_helper.rb"
contents = File.read(destination_file_path)

module_declaration = "require \"#{gem_namespace}\"\n"
contents.gsub!("require \"webmock/rspec", module_declaration + "require \"webmock/rspec")

File.open(destination_file_path, "w") { |file| file.write(contents) }

puts "Create fixtures folder"
FileUtils.mkdir_p("spec/fixtures")

puts "Create resources folder"
FileUtils.mkdir_p("spec/resources")

puts "Create support folder"
FileUtils.mkdir_p("spec/support")

puts "Copy match_fixture"
FileUtils.copy(File.join(templates_folder, "match_fixture.rb"), "spec/support/match_fixture.rb")

puts "Copy mock_helper"
FileUtils.copy(File.join(templates_folder, "mock_helper.rb"), "spec/support/mock_helper.rb")

puts "Copy .rspec"
FileUtils.copy(File.join(templates_folder, ".rspec"), ".rspec")
