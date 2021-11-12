# frozen_string_literal: true

module TodoItems
  class Complete
    include RailsEventSourcing::Command

    attributes :todo_item

    def build_event
      TodoItems::Completed.new(todo_item: todo_item)
    end

    def noop?
      todo_item.completed?
    end
  end
end
