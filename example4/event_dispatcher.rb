# frozen_string_literal: true

module EventsCore
  module EventDispatcher
    HANDLERS = {}.freeze
    ASYNC_HANDLERS = {}.freeze

    class NoHandlerAvailable < StandardError; end

    class HandlerError < StandardError; end

    class HandlerExtendedError < StandardError
      attr_reader :payload

      def initialize(message, payload = nil)
        super(message)
        @payload = payload
      end
    end

    def self.dispatch(event)
      handlers(event.class).each do |handler|
        handle(handler, event)
      end
    end

    def self.dispatch_async(event)
      async_handlers(event.class).each do |handler|
        Jobs::EventsCore::EventHandlerJob.new(
          handler_klass: handler.to_s,
          event_klass: event.class.to_s,
          payload: event.to_json
        ).enqueue
      end
    end

    def self.handlers(event_class)
      HANDLERS.fetch(event_class.to_s) do
        raise NoHandlerAvailable, "No handler available for #{event_class}"
      end
    end
    private_class_method :handlers

    def self.async_handlers(event_class)
      ASYNC_HANDLERS.fetch(event_class.to_s) do
        raise NoHandlerAvailable, "No async handler available for #{event_class}"
      end
    end
    private_class_method :async_handlers

    def self.handle(handler, event)
      log_info("Executing #{handler} with #{event.to_h}")

      case handler.handle(event)
      in Dry::Monads::Success
        log_info("#{handler} executed successfully. Event: #{event.to_h}")
      in Dry::Monads::Failure(Hash => payload)
        error = payload.delete(:message) || "Execution failed"
        log_error("#{handler} failed to execute. Error: #{error} Payload: #{payload} Event: #{event.to_h}")
        raise HandlerExtendedError.new(error, payload)
      in Dry::Monads::Failure(error)
        log_error("#{handler} failed to execute. Error: #{error} Event: #{event.to_h}")
        raise HandlerError.new(error)
      else
        log_error("#{handler} failed to execute with unknown error. Event: #{event.to_h}")
        raise HandlerError.new("Execution failed")
      end
    end

    def self.log_info(message)
      Rails.logger.tagged(self) { _1.info(message)}
    end
    private_class_method :log_info

    def self.log_error(message)
      Rails.logger.tagged(self) { _1.error(message)}
    end
    private_class_method :log_error
  end
end
