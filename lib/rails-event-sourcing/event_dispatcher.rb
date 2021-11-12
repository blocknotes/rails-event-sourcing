# frozen_string_literal: true

module RailsEventSourcing
  # Dispatcher implementation used by Events on after save.
  class EventDispatcher
    class << self
      # Register Reactors to Events.
      # * Reactors registered with `trigger` will be triggered synchronously
      # * Reactors registered with `async` will be triggered asynchronously via a Sidekiq Job
      #
      # Example:
      #
      #   on SomeEvent, trigger: ->(item) { puts "Callable block on #{item.id}" }
      #   on BaseEvent, trigger: LogEvent, async: TrackEvent
      #   on PledgeCancelled, PaymentFailed, async: [NotifyAdmin, CreateTask]
      #   on [PledgeCancelled, PaymentFailed], async: [NotifyAdmin, CreateTask]
      #
      def on(*events, trigger: [], async: [])
        rules.register(events: events.flatten, sync: Array(trigger), async: Array(async))
      end

      # Dispatches events to matching Reactors once.
      # Called by all events after they are created.
      def dispatch(event)
        reactors = rules.for(event)
        reactors.sync.each { |reactor| reactor.call(event) }
        reactors.async.each { |reactor| ReactorJob.perform_later(event, reactor.to_s) }
      end

      def rules
        @@rules ||= RuleSet.new # rubocop:disable Style/ClassVars
      end
    end

    class RuleSet
      def initialize
        @rules = Hash.new { |h, k| h[k] = ReactorSet.new }
      end

      def register(events:, sync:, async:)
        events.each do |event|
          @rules[event].add_sync(sync)
          @rules[event].add_async(async)
        end
      end

      # Return a ReactorSet containing all Reactors matching an Event
      def for(event)
        reactors = ReactorSet.new

        @rules.each do |event_class, rule|
          # Match event by class including ancestors. e.g. All events match a role for BaseEvent.
          if event.is_a?(event_class)
            reactors.add_sync(rule.sync)
            reactors.add_async(rule.async)
          end
        end

        reactors
      end
    end

    # Contains sync and async reactors. Used to:
    # * store reactors via Rules#register
    # * return a set of matching reactors with Rules#for
    class ReactorSet
      attr_reader :sync, :async

      def initialize
        @sync = Set.new
        @async = Set.new
      end

      def add_sync(reactors)
        @sync += reactors
      end

      def add_async(reactors)
        @async += reactors
      end
    end
  end
end
