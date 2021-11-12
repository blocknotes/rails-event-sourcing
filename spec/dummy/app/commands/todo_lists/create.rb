# frozen_string_literal: true

module TodoLists
  class Create
    include RailsEventSourcing::Command

    attributes :name

    def build_event
      TodoLists::Created.new(name: name)
    end
  end
end
