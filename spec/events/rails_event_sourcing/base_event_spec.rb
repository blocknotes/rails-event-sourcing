# frozen_string_literal: true

RSpec.describe RailsEventSourcing::BaseEvent do
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

  it 'raises an excpetion when instantiated' do
    expect { described_class.new }.to raise_exception(NotImplementedError, /an abstract class and cannot be instantiated/)
  end

  describe 'callback: before_validation' do
    it 'builds an aggregated object' do
      some_event = SomeEvent.new
      expect { some_event.valid? }.to change(some_event, :aggregate).from(nil).to(instance_of(TodoList))
    end
  end

  describe 'callback: before_create' do
    it do
      some_event = SomeEvent.new(name: 'Some name')
      allow(some_event).to receive(:persisted?).and_call_original
      some_event.save!
      expect(some_event).to have_received(:persisted?)
    end
  end

  describe 'callback: after_create' do
    before do
      allow(RailsEventSourcing::Dispatcher).to receive(:dispatch)
      SomeEvent.create!(name: 'Some name')
    end

    it 'calls dispatch on Dispatcher' do
      expect(RailsEventSourcing::Dispatcher).to have_received(:dispatch)
    end
  end

  describe 'callback: after_initialize' do
    it 'prepares an empty hash for data' do
      some_event = SomeEvent.new
      expect(some_event.data).to eq({})
    end

    it 'prepares an empty hash for metadata' do
      some_event = SomeEvent.new
      expect(some_event.metadata).to eq({})
    end
  end

  describe '#aggregate' do
    subject(:aggregate) { SomeEvent.new(todo_list: todo_list).aggregate }

    let(:todo_list) { TodoList.create!(name: 'Some list') }

    it 'returns the associated record' do
      expect(aggregate).to eq todo_list
    end
  end

  describe '#aggregate=' do
    subject(:set_aggregate) { some_event.aggregate = todo_list }

    let(:some_event) { SomeEvent.new }
    let(:todo_list) { TodoList.create!(name: 'Some list') }

    it 'associates a new record to the event' do
      expect { set_aggregate }.to change(some_event, :aggregate).from(nil).to(todo_list)
    end
  end

  describe '#aggregate_id' do
    subject(:aggregate_id) { SomeEvent.new(todo_list: todo_list).aggregate_id }

    let(:todo_list) { TodoList.create!(name: 'Some list') }

    it 'returns the associated record' do
      expect(aggregate_id).to eq todo_list.id
    end
  end

  describe '#aggregate_id=' do
    subject(:set_aggregate_id) { some_event.aggregate_id = todo_list.id }

    let(:some_event) { SomeEvent.new }
    let(:todo_list) { TodoList.create!(name: 'Some list') }

    it 'associates a new record to the event' do
      expect { set_aggregate_id }.to change(some_event, :aggregate_id).from(nil).to(todo_list.id)
    end
  end

  describe '#build_aggregate' do
    subject(:build_aggregate) { SomeEvent.new.build_aggregate }

    it 'builds a new aggregate instance' do
      expect(build_aggregate).to be_a TodoList
    end
  end

  describe '#aggregate_name' do
    subject(:aggregate_name) { SomeEvent.new.aggregate_name }

    before do
      allow(SomeEvent).to receive(:aggregate_name).and_return(:an_aggregate_name)
    end

    it 'delegates the method to the class' do
      expect(aggregate_name).to eq :an_aggregate_name
    end
  end

  describe '#apply' do
    subject(:apply) { some_event.apply(todo_list) }

    let(:some_event) { SomeEvent.new }
    let(:todo_list) { instance_double('TodoList', name: 'A test', 'name=': true) }

    it 'assigns the attributes to the aggregated item' do
      apply
      expect(todo_list).to have_received(:'name=')
    end

    context 'with a derived class without apply defined' do
      let(:event_class) do
        Class.new(described_class) do
          self.table_name = 'todo_list_events'
        end
      end

      it 'raises a NotImplementedError exception' do
        expect { apply }.to raise_exception(NotImplementedError)
      end
    end
  end

  describe '#rollback!' do
    let(:first_event) { SomeEvent.create!(name: 'First') }
    let(:second_event) { SomeEvent.create!(name: 'Second', todo_list: todo_list) }
    let(:third_event) { SomeEvent.create!(name: 'Third', todo_list: todo_list) }
    let(:todo_list) { TodoList.last }

    it 'rollbacks to a specific version', :aggregate_failures do
      expect { first_event }.to change(TodoList, :count).by(1)
      expect { second_event }.to change(todo_list, :name).from('First').to('Second')
      expect { third_event }.to change(todo_list, :name).from('Second').to('Third')
      expect { second_event.rollback! }.to(
        change(todo_list, :name).from('Third').to('Second').and(
          change(SomeEvent, :count).by(-1)
        )
      )
    end

    context 'with an event which is not a subclass of BaseEvent' do
      it do
        first_event = SomeEvent.create!(name: 'First')
        second_event = SomeEvent.create!(name: 'Second', todo_list: todo_list)
        expect { first_event.rollback! }.to change {
          SomeEvent.exists?(id: second_event.id)
        }.from(true).to(false)
      end
    end
  end

  describe '.aggregate_name' do
    subject(:aggregate_name) { SomeEvent.new.aggregate_name }

    it 'returns the aggregate name' do
      expect(aggregate_name).to eq :todo_list
    end
  end

  describe '.data_attributes' do
    subject(:data_attributes) { SomeEvent.data_attributes('field1', 'field2', 'field3') }

    let(:some_event) { SomeEvent.new }

    it 'adds data attributes', :aggregate_failures do
      expect(data_attributes).to eq %w[name field1 field2 field3]
      expect(some_event).to respond_to(:field3)
      expect(some_event).to respond_to(:field3=)
    end
  end

  describe '.event_name' do
    subject(:event_name) { SomeEvent.event_name }

    it 'returns the aggregate name' do
      expect(event_name).to eq 'some_event'
    end
  end

  describe '.events_for' do
    subject(:events_for) { SomeEvent.events_for(todo_list) }

    let(:todo_list) { TodoList.last }

    it 'returns the list of events for a specific entity' do
      events = [
        SomeEvent.create!(name: 'First'),
        SomeEvent.create!(name: 'Second', todo_list: todo_list),
        SomeEvent.create!(name: 'Third', todo_list: todo_list)
      ]
      expect(events_for).to match(events)
    end
  end

  describe '.reserved_column_names' do
    subject(:reserved_column_names) { SomeEvent.reserved_column_names }

    it { is_expected.to eq %w[id created_at updated_at] }
  end
end
