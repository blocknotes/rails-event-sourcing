# frozen_string_literal: true

class TodoListsDispatcher < RailsEventSourcing::EventDispatcher
  on TodoLists::Created, trigger: ->(todo_list) { puts ">>> TodoLists::Created [##{todo_list.id}]" }
end
