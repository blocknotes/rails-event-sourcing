# frozen_string_literal: true

class TodoItemsDispatcher < RailsEventSourcing::EventDispatcher
  on TodoItems::Completed, trigger: ->(todo_item) { puts ">>> TodoItems::Completed [##{todo_item.id}]" }
end
