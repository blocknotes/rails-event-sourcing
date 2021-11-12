# frozen_string_literal: true

module TodoItems
  class Uncompleted < TodoItems::BaseEvent
    def apply(todo_item)
      todo_item.completed = false

      todo_item
    end
  end
end
