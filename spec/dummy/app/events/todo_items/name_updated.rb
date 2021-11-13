# frozen_string_literal: true

module TodoItems
  class NameUpdated < TodoItems::Event
    data_attributes :name

    def apply(todo_item)
      todo_item.name = name

      todo_item
    end
  end
end
