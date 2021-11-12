# frozen_string_literal: true

module TodoItems
  class Create
    include RailsEventSourcing::Command

    attributes :todo_list, :name

    def build_event
      TodoItems::Created.new(todo_list_id: todo_list.id, name: name)
    end
  end
end
