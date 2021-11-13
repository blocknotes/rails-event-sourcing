# frozen_string_literal: true

RSpec.describe 'Events' do
  describe 'creating events' do
    subject(:create_event) { TodoLists::Created.create!(options) }

    context 'without the required attributes' do
      let(:options) { {} }

      it 'raises a validation exception' do
        expect { create_event }.to(
          raise_exception(ActiveRecord::RecordInvalid, /Name can't be blank/).and(
            change(TodoList, :count).by(0).and(
              change(TodoLists::Event, :count).by(0)
            )
          )
        )
      end
    end

    context 'with the required attributes' do
      let(:options) { { name: 'My TODO 1' } }

      it 'creates the aggregated record and the event record' do
        expect { create_event }.to(
          change(TodoList, :count).by(1).and(
            change(TodoLists::Event, :count).by(1)
          )
        )
      end
    end

    context 'when the transaction fails' do
      subject(:create_event) { SomeEvent.create! }

      let(:todo_list_new_class) do
        Class.new(ApplicationRecord) do
          self.table_name = 'todo_lists'
        end
      end

      let(:some_event_class) do
        Class.new(RailsEventSourcing::BaseEvent) do
          self.table_name = 'todo_list_events'
          belongs_to :todo_list, class_name: 'TodoListNew', autosave: false
          data_attributes :name

          def apply(todo_list)
            todo_list
          end
        end
      end

      before do
        stub_const('TodoListNew', todo_list_new_class)
        stub_const('SomeEvent', some_event_class)
      end

      it do
        expect { create_event }.to(
          raise_exception(ActiveRecord::NotNullViolation).and(
            change(TodoList, :count).by(0).and(
              change(TodoLists::Event, :count).by(0)
            )
          )
        )
      end
    end
  end
end
