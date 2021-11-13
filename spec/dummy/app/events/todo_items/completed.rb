# frozen_string_literal: true

module TodoItems
  class Completed < TodoItems::Event
    def apply(todo_item)
      todo_item.completed = true

      todo_item
    end
  end
end
