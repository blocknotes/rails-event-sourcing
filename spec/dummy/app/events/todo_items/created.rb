# frozen_string_literal: true

module TodoItems
  class Created < TodoItems::BaseEvent
    data_attributes :todo_list_id, :name

    def apply(todo_item)
      todo_item.todo_list_id = todo_list_id
      todo_item.name = name

      todo_item
    end
  end
end
