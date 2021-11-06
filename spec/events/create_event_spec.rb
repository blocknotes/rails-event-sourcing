# frozen_string_literal: true

RSpec.describe 'Create event' do # rubocop:disable RSpec/DescribeClass
  context 'without the required attributes' do
    subject(:create_event) { TodoLists::Created.create! }

    it 'raises a validation exception' do
      expect { create_event }.to(
        raise_exception(ActiveRecord::RecordInvalid, /Name can't be blank/).and(
          change(TodoList, :count).by(0).and(
            change(TodoLists::BaseEvent, :count).by(0)
          )
        )
      )
    end
  end

  context 'with the required attributes' do
    subject(:create_event) { TodoLists::Created.create!(name: 'My TODO 1') }

    it 'creates the aggregated record and the event record' do
      expect { create_event }.to(
        change(TodoList, :count).by(1).and(
          change(TodoLists::BaseEvent, :count).by(1)
        )
      )
    end
  end
end
