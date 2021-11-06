# frozen_string_literal: true

RSpec.describe RailsEventSourcing::BaseEvent do
  subject(:base_event) { described_class.new }

  let(:todo_list_event_class) do
    Class.new(described_class) do
      self.table_name = 'todo_list_events'

      belongs_to :todo_list

      data_attributes :name

      def apply(todo_list)
        todo_list.name = name
        todo_list
      end

      def self.name
        'TodoList::Event'
      end
    end
  end
  let(:todo_list_event) { todo_list_event_class.new }

  it 'raises an excpetion when instantiated' do
    expect { base_event }.to raise_exception(NotImplementedError, /an abstract class and cannot be instantiated/)
  end

  describe 'callback: before_validation' do
    it 'builds an aggregated object' do
      expect { todo_list_event.valid? }.to change(todo_list_event, :aggregate).from(nil).to(instance_of(TodoList))
    end
  end

  describe 'callback: before_create' do
    let(:some_event_class) { Class.new(todo_list_event_class) }

    before do
      stub_const('SomeEvent', some_event_class)
    end

    it do
      event = todo_list_event_class.new(name: 'Some name', type: 'SomeEvent')
      allow(event).to receive(:persisted?).and_call_original
      event.save!
      expect(event).to have_received(:persisted?)
    end
  end

  describe 'callback: after_create' do
    let(:some_event_class) { Class.new(todo_list_event_class) }

    before do
      stub_const('SomeEvent', some_event_class)
      allow(RailsEventSourcing::EventDispatcher).to receive(:dispatch)
      todo_list_event_class.create!(name: 'Some name', type: 'SomeEvent')
    end

    it 'calls dispatch on EventDispatcher' do
      expect(RailsEventSourcing::EventDispatcher).to have_received(:dispatch)
    end
  end

  describe 'callback: after_initialize' do
    it 'prepares an empty hash for data' do
      expect(todo_list_event.data).to eq({})
    end

    it 'prepares an empty hash for metadata' do
      expect(todo_list_event.metadata).to eq({})
    end
  end

  describe '#aggregate' do
    subject(:aggregate) { todo_list_event_class.new(todo_list: todo_list).aggregate }

    let(:todo_list) { TodoList.create!(name: 'Some list') }

    it 'returns the associated record' do
      expect(aggregate).to eq todo_list
    end
  end

  describe '#aggregate=' do
    subject(:set_aggregate) { todo_list_event.aggregate = todo_list }

    let(:todo_list) { TodoList.create!(name: 'Some list') }

    it 'associates a new record to the event' do
      expect { set_aggregate }.to change(todo_list_event, :aggregate).from(nil).to(todo_list)
    end
  end

  describe '#aggregate_id' do
    subject(:aggregate_id) { todo_list_event_class.new(todo_list: todo_list).aggregate_id }

    let(:todo_list) { TodoList.create!(name: 'Some list') }

    it 'returns the associated record' do
      expect(aggregate_id).to eq todo_list.id
    end
  end

  describe '#aggregate_id=' do
    subject(:set_aggregate_id) { todo_list_event.aggregate_id = todo_list.id }

    let(:todo_list) { TodoList.create!(name: 'Some list') }

    it 'associates a new record to the event' do
      expect { set_aggregate_id }.to change(todo_list_event, :aggregate_id).from(nil).to(todo_list.id)
    end
  end

  describe '#build_aggregate' do
    subject(:build_aggregate) { todo_list_event.build_aggregate }

    it 'builds a new aggregate instance' do
      expect(build_aggregate).to be_a TodoList
    end
  end

  describe '#aggregate_name' do
    subject(:aggregate_name) { todo_list_event.aggregate_name }

    before do
      allow(todo_list_event_class).to receive(:aggregate_name).and_return(:an_aggregate_name)
    end

    it 'delegates the method to the class' do
      expect(aggregate_name).to eq :an_aggregate_name
    end
  end

  describe '#apply' do
    subject(:apply) { todo_list_event.apply(todo_list) }

    let(:todo_list) { instance_double('TodoList', name: 'A test', 'name=': true) }

    it 'assigns the attributes to the aggregated item' do
      apply
      expect(todo_list).to have_received(:'name=')
    end

    context 'with a derived class without apply defined' do
      let(:todo_list_event_class) do
        Class.new(described_class) do
          self.table_name = 'todo_list_events'
        end
      end

      it 'raises a NotImplementedError exception' do
        expect { apply }.to raise_exception(NotImplementedError)
      end
    end
  end

  describe '.aggregate_name' do
    subject(:aggregate_name) { todo_list_event_class.aggregate_name }

    it 'returns the aggregate name' do
      expect(aggregate_name).to eq :todo_list
    end
  end

  describe '.data_attributes' do
    subject(:data_attributes) { todo_list_event_class.data_attributes('field1', 'field2', 'field3') }

    it 'adds data attributes', :aggregate_failures do
      expect(data_attributes).to eq %w[name field1 field2 field3]
      expect(todo_list_event).to respond_to(:field3)
      expect(todo_list_event).to respond_to(:field3=)
    end
  end

  describe '.event_name' do
    subject(:event_name) { todo_list_event_class.event_name }

    it 'returns the aggregate name' do
      expect(event_name).to eq 'todo_list/event'
    end
  end
end
