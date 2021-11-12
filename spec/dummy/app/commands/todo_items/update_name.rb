# frozen_string_literal: true

module TodoItems
  class UpdateName
    include RailsEventSourcing::Command

    attributes :todo_item, :name

    def build_event
      TodoItems::NameUpdated.new(todo_item: todo_item, name: name)
    end

    def noop?
      name == todo_item.name
    end
  end
end
