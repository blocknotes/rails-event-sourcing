# frozen_string_literal: true

module TodoLists
  class BaseEvent < RailsEventSourcing::BaseEvent
    self.table_name = "todo_list_events"

    belongs_to :todo_list, class_name: "::TodoList", autosave: false
  end
end
