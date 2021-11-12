class TodoList < ApplicationRecord
  has_many :todo_items

  validates :name, presence: true
end
