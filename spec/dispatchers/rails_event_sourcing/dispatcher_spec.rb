# frozen_string_literal: true

RSpec.describe RailsEventSourcing::Dispatcher do
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

  before do
    stub_const('SomeBaseEvent', base_event_class)
    stub_const('SomeEvent', event_class)
  end

  context 'with a sync reactor' do
    let(:dispatcher_class) do
      Class.new(described_class) do
        on SomeEvent, trigger: ->(entity) { Rails.logger.info("Some event [##{entity.id}]") }
      end
    end

    before do
      dispatcher_class # load the class to setup the triggers
      allow(Rails.logger).to receive(:info)
    end

    it 'executes the trigger after the event creation' do
      SomeEvent.create!(name: 'Some name')
      expect(Rails.logger).to have_received(:info).with(/Some event \[#\d+\]/)
    end
  end

  context 'with an async reactor' do
    let(:another_event_class) do
      Class.new(SomeBaseEvent) do
        def apply(todo_list)
          todo_list
        end
      end
    end

    let(:dispatcher_class) do
      Class.new(described_class) do
        on SomeEvent, async: AnotherEvent
      end
    end

    before do
      stub_const('AnotherEvent', another_event_class)
      dispatcher_class # load the class to setup the triggers
      allow(RailsEventSourcing::ReactorJob).to receive(:perform_later)
    end

    it 'schedules the job after the event creation' do
      event = SomeEvent.create!(name: 'Some name')
      expect(RailsEventSourcing::ReactorJob).to have_received(:perform_later).with(event, 'AnotherEvent')
    end
  end
end
