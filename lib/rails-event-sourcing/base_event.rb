# frozen_string_literal: true

module RailsEventSourcing
  # This is the BaseEvent class that all Events inherit from.
  # It takes care of serializing `data` and `metadata` via json
  # It defines setters and accessors for the defined `data_attributes`
  # After create, it calls `apply` to apply changes.
  class BaseEvent < ::ActiveRecord::Base
    self.abstract_class = true

    serialize :data, JSON
    serialize :metadata, JSON

    before_validation :preset_aggregate
    before_create :apply_and_persist
    after_create :dispatch

    after_initialize do
      self.data ||= {}
      self.metadata ||= {}
    end

    scope :recent_first, -> { reorder('id DESC') }

    def aggregate
      public_send aggregate_name
    end

    def aggregate=(model)
      public_send "#{aggregate_name}=", model
    end

    def aggregate_id=(id)
      public_send "#{aggregate_name}_id=", id
    end

    # Apply the event to the aggregate passed in.
    # Must return the aggregate.
    def apply(aggregate)
      raise NotImplementedError
    end

    def aggregate_id
      public_send "#{aggregate_name}_id"
    end

    def build_aggregate
      public_send "build_#{aggregate_name}"
    end

    # Rollback an aggregate entity to a specific version
    #
    # Update the aggregate with the changes up to the current event and
    # destroys the events after
    def rollback!
      base_class = self.class.superclass == RailsEventSourcing::BaseEvent ? self.class : self.class.superclass
      new_attributes = aggregate.class.new.attributes
      preserve_columns = new_attributes.keys - base_class.reserved_column_names
      new_attributes.slice!(*preserve_columns)
      aggregate.assign_attributes(new_attributes)
      aggregate.transaction do
        base_class.events_for(aggregate).where('id > ?', id).destroy_all
        base_class.events_for(aggregate).reorder('id ASC').each do |event|
          event.apply(aggregate)
        end
        aggregate.save!
      end
    end

    delegate :aggregate_name, to: :class

    class << self
      def aggregate_name
        inferred_aggregate = reflect_on_all_associations(:belongs_to).first
        raise "Events must belong to an aggregate" if inferred_aggregate.nil?

        inferred_aggregate.name
      end

      # Define attributes to be serialize in the `data` column.
      # It generates setters and getters for those.
      #
      # Example:
      #
      # class MyEvent < RailsEventSourcing::BaseEvent
      #   data_attributes :title, :description, :drop_id
      # end
      def data_attributes(*attrs)
        @data_attributes ||= []

        attrs.map(&:to_s).each do |attr|
          @data_attributes << attr unless @data_attributes.include?(attr)

          define_method attr do
            self.data ||= {}
            self.data[attr]
          end

          define_method "#{attr}=" do |arg|
            self.data ||= {}
            self.data[attr] = arg
          end
        end

        @data_attributes
      end

      # Underscored class name by default. ex: "post/updated"
      # Used when sending events to the data pipeline
      def event_name
        name.underscore
      end

      def events_for(aggregate)
        where(aggregate_name => aggregate)
      end

      def reserved_column_names
        %w[id created_at updated_at]
      end
    end

    private

    # Build aggregate when the event is creating an aggregate
    def preset_aggregate
      self.aggregate ||= build_aggregate
    end

    # Apply the transformation to the aggregate and save it
    def apply_and_persist
      aggregate.lock! if aggregate.persisted?
      self.aggregate = apply(aggregate)
      aggregate.save!
      self.aggregate_id = aggregate.id if aggregate_id.nil?
    end

    def dispatch
      Dispatcher.dispatch(self)
    end
  end
end
