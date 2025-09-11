require "rake"

module Drasil
  class Tasks
    include Rake::DSL if defined?(Rake::DSL)

    def install_tasks
      Dir.glob(File.join(File.dirname(__FILE__), "../tasks/**/*.rake")).each { |r| load r }
    end
  end
end

Drasil::Tasks.new.install_tasks
