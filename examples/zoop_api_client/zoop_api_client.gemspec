# frozen_string_literal: true

require_relative "lib/zoop_api_client/version"

Gem::Specification.new do |spec|
  spec.name = "zoop_api_client"
  spec.version = ZoopApiClient::VERSION
  spec.authors = ["Lucas Sousa", "João Alves"]
  spec.email = ["joao.alves@reserva.ink"]

  spec.summary = "Zoop API Client"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec"
end
