# frozen_string_literal: true

require_relative "lib/drasil/version"

Gem::Specification.new do |spec|
  spec.name = "drasil"
  spec.summary = "Base Drasil to create api clients."
  spec.version = Drasil::VERSION
  spec.authors = ["Lucas Sousa", "João Alves"]
  spec.email = ["joao.alves@reserva.ink"]

  spec.required_ruby_version = ">= 2.6.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "spyke"
  spec.add_dependency 'multi_json', '~> 1.15'
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "byebug"
end
