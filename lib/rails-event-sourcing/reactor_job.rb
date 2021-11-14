# frozen_string_literal: true

if defined? ActiveJob
  module RailsEventSourcing
    class ReactorJob < ActiveJob::Base
      def perform(event, reactor_class)
        reactor = reactor_class.constantize
        if reactor.ancestors.include? RailsEventSourcing::BaseEvent
          reactor.create!(aggregate: event.aggregate)
        end
      end
    end
  end
end
