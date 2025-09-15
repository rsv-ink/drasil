# frozen_string_literal: true

namespace :drasil do
  desc "Install drasil"
  task :install do
    filepath = File.expand_path("../../install/install.rb",  __dir__)
    dirname  = File.dirname(filepath)
    system("ruby #{filepath} #{dirname}")
  end
end
