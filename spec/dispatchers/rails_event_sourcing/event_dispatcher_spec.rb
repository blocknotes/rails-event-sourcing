# frozen_string_literal: true

RSpec.describe RailsEventSourcing::EventDispatcher do
  let(:event_class) do
    Class.new(RailsEventSourcing::BaseEvent) do
      self.table_name = 'todo_list_events'

      belongs_to :todo_list

      data_attributes :name

      def apply(todo_list)
        todo_list.name = name
        todo_list
      end
    end
  end

  let(:dispatcher_class) do
    Class.new(described_class) do
      on SomeEvent, trigger: ->(todo_list) { Rails.logger.info("TodoList event - #{todo_list.id}") }
    end
  end

  context 'when the dispatcher class is loaded' do
    before do
      stub_const('SomeEvent', event_class)
      dispatcher_class # load the class to setup the triggers
      allow(Rails.logger).to receive(:info)
    end

    it 'executes the trigger after the event creation' do
      SomeEvent.create!(name: 'Some name', type: 'SomeEvent')
      expect(Rails.logger).to have_received(:info).with(/TodoList event - /)
    end
  end
end
