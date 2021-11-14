# frozen_string_literal: true

RSpec.describe RailsEventSourcing::ReactorJob do
  let(:base_event_class) do
    Class.new(RailsEventSourcing::BaseEvent) do
      self.table_name = 'todo_list_events'

      belongs_to :todo_list
    end
  end

  let(:event_class) do
    Class.new(SomeBaseEvent) do
      data_attributes :name

      def apply(todo_list)
        todo_list.name = name
        todo_list
      end
    end
  end

  let(:another_event_class) do
    Class.new(SomeBaseEvent) do
      def apply(todo_list)
        todo_list.name = '###'
        todo_list
      end
    end
  end

  before do
    stub_const('SomeBaseEvent', base_event_class)
    stub_const('SomeEvent', event_class)
    stub_const('AnotherEvent', another_event_class)
  end

  describe '#perform' do
    subject(:perform_now) { described_class.perform_now(event, 'AnotherEvent') }

    let(:event) { SomeEvent.create!(name: 'Test 1') }

    before do
      event
    end

    it do
      expect { perform_now }.to change { TodoList.last.name }.from('Test 1').to('###')
    end
  end
end
