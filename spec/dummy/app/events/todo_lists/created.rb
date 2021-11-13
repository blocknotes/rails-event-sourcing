# frozen_string_literal: true

module TodoLists
  class Created < TodoLists::Event
    data_attributes :name

    def apply(todo_list)
      todo_list.name = name

      todo_list
    end
  end
end
