# frozen_string_literal: true

RSpec.describe RailsEventSourcing::Command do
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

  let(:command_class) do
    Class.new do
      include RailsEventSourcing::Command

      attributes :arg1

      def build_event
        SomeEvent.new(name: 'An event')
      end
    end
  end

  before do
    stub_const('SomeBaseEvent', base_event_class)
    stub_const('SomeEvent', event_class)
  end

  describe '.attributes' do
    let(:command_class) do
      Class.new do
        include RailsEventSourcing::Command

        attributes :arg1, :arg2, :arg3
      end
    end

    it 'raises an ArgumentError exception' do
      expect { command_class.new }.to raise_exception(ArgumentError, /missing keywords:.*arg1,.*arg2,.*arg3/)
    end

    it 'attachs the arguments to the command context' do
      command = command_class.new(arg1: :a, arg2: :b, arg3: :c)
      expect(command.arg3).to eq(:c)
    end
  end

  describe '.call' do
    subject(:call) { command_class.call(arg1: nil) }

    let!(:command) { instance_double(command_class, call: true) }

    before do
      allow(command_class).to receive(:new).and_return(command)
    end

    it 'delegates the method call to an instance', :aggregate_failures do
      call
      expect(command_class).to have_received(:new).with(arg1: nil)
      expect(command).to have_received(:call)
    end
  end

  describe '#call' do
    subject(:call) { command_class.new(arg1: nil).call }

    context 'when build_event is not implemented' do
      let(:command_class) do
        Class.new do
          include RailsEventSourcing::Command

          attributes :arg1
        end
      end

      it 'raises a NotImplementedError exception' do
        expect { call }.to raise_exception(NotImplementedError)
      end
    end

    it 'triggers the defined event' do
      expect(call).to be_a SomeEvent
    end
  end

  describe '#event' do
    subject(:event) { command_class.new(arg1: nil).event }

    it 'returns the associated event' do
      expect(event).to be_a SomeEvent
    end
  end

  describe '#noop?' do
    subject(:noop?) { command_class.new(arg1: nil).noop? }

    it { is_expected.to be_falsey }

    context 'when a command overrides noop?' do
      let(:command_class) do
        Class.new do
          include RailsEventSourcing::Command

          attributes :arg1

          def build_event
            SomeEvent.new(name: 'An event')
          end

          def noop?
            arg1 == :no_changes_needed
          end
        end
      end

      before do
        allow(SomeEvent).to receive(:new).and_call_original
      end

      it "executes the command if noop? is falsey", :aggregate_failures do
        command = command_class.new(arg1: nil)
        expect(command).not_to be_noop
        command.call
        expect(SomeEvent).to have_received(:new)
      end

      it "doesn't execute the command if noop? is truthy", :aggregate_failures do
        command = command_class.new(arg1: :no_changes_needed)
        expect(command).to be_noop
        command.call
        expect(SomeEvent).not_to have_received(:new)
      end
    end
  end

  describe 'command validation' do
    subject(:validate!) { command.validate! }

    let(:command) { command_class.new(arg1: nil) }

    it { is_expected.to be_truthy }

    context 'when the command is not valid' do
      before do
        allow(command).to receive(:valid?).and_return(false)
      end

      it 'raises a ValidationError exception' do
        expect { validate! }.to raise_exception(ActiveModel::ValidationError, /Validation failed/)
      end
    end
  end
end
