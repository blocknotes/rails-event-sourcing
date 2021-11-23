# frozen_string_literal: true

module Events
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    def create_initializer
      initializer 'rails_event_sourcing.rb', <<~FILE
        # Preload dispatchers classes
        Rails.root.join('app').glob('**/*_dispatcher.rb').sort.each do |path|
          require(path.to_s)
        end
      FILE
    end
  end
end
