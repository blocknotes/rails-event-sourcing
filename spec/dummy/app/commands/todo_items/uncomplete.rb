# frozen_string_literal: true

module TodoItems
  class Uncomplete
    include RailsEventSourcing::Command

    attributes :todo_item

    def build_event
      TodoItems::Uncompleted.new(todo_item: todo_item)
    end

    def noop?
      !todo_item.completed?
    end
  end
end
