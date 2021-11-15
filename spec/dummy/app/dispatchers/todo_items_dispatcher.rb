# frozen_string_literal: true

class TodoItemsDispatcher < RailsEventSourcing::Dispatcher
  on TodoItems::Created, async: TodoItems::Completed
  on TodoItems::Completed, trigger: ->(todo_item) { puts ">>> TodoItems::Completed [##{todo_item.id}]" }
end
