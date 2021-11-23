# frozen_string_literal: true

module Events
  class EventGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def create_event_model_file
      parts = name.split('/')
      abort('> Required format: namespace/event_name') unless parts.size == 2

      namespace, event = parts
      base_class = "#{namespace.camelize}::Event"
      create_base_event_model_file(namespace: namespace, base_class: base_class)

      attrs = prepare_data_attributes(args)
      apply_method = prepare_method_apply(args)

      create_file "app/events/#{namespace}/#{event}_event.rb", <<~FILE
        class #{class_name}Event < #{base_class}
          #{attrs}def apply(source)
            #{apply_method}source
          end
        end
      FILE
    end

    private

    def create_base_event_model_file(namespace:, base_class:)
      model_name = namespace.singularize
      table_name = "#{model_name}_events"

      create_file "app/events/#{namespace}/event.rb", <<~FILE
        class #{base_class} < RailsEventSourcing::BaseEvent
          self.table_name = "#{table_name}"

          belongs_to :#{model_name}, class_name: "::#{model_name.classify}", autosave: false
        end
      FILE
    end

    def prepare_data_attributes(args)
      return if args.empty?

      "data_attributes :#{args.join(', :')}\n\n  "
    end

    def prepare_method_apply(args)
      return if args.empty?

      sources = args.map { |a| "source.#{a} = #{a}" }
      sources << ['']
      sources.join("\n    ")
    end
  end
end
