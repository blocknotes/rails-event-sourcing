# frozen_string_literal: true

module TodoLists
  class UpdateName
    include RailsEventSourcing::Command

    attributes :todo_list, :name

    def build_event
      TodoLists::NameUpdated.new(todo_list: todo_list, name: name)
    end

    def noop?
      name == todo_list.name
    end
  end
end
