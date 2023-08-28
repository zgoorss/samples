require "rails_helper"

RSpec.describe EventsCore::EventDispatcher do
  let(:handler_class) { ExampleHandler }
  let(:event) { ExamplePerformedEevent.new }
  let(:handler) { instance_double(handler_class) }

  before do
    allow(handler_class).to receive(:new).with(event).and_return(handler)
  end

  describe "#dispatch" do
    context "when a handler is available" do
      it "calls the handle method of the handler" do
        expect(handler).to receive(:handle).and_return(Dry::Monads::Success())
        described_class.dispatch(event)
      end

      it "logs a success message when the handler is successful" do
        allow(handler).to receive(:handle).and_return(Dry::Monads::Success())
        expect(Rails.logger).to receive(:info).with(/Executing/)
        expect(Rails.logger).to receive(:info).with(/executed successfully/)
        described_class.dispatch(event)
      end

      context "when the handler returns a failure" do
        it "raises a HandlerError with error message" do
          allow(handler).to receive(:handle).and_return(Dry::Monads::Failure("error message"))
          expect { described_class.dispatch(event) }.to raise_error(EventsCore::EventDispatcher::HandlerError, "error message")
        end

        it "raises a HandlerError with unknown failure" do
          allow(handler).to receive(:handle).and_return(Dry::Monads::Failure())
          expect { described_class.dispatch(event) }.to raise_error(EventsCore::EventDispatcher::HandlerError, "Execution failed")
        end

        it "raises a HandlerExtendedError with payload as a hash" do
          allow(handler).to receive(:handle).and_return(Dry::Monads::Failure(message: "Something went wrong", errors: ["error 1", "error 2"]))
          expect { described_class.dispatch(event) }.to raise_error(EventsCore::EventDispatcher::HandlerExtendedError, "Something went wrong") do |error|
            error.payload == { errors: ["error 1", "error 2"] }
          end
        end
      end
    end

    context "when no handler is available" do
      let(:unknown_event) { double("UnknownEvent", class: Class.new) }

      it "raises a NoHandlerAvailable error" do
        expect { described_class.dispatch(unknown_event) }.to raise_error(EventsCore::EventDispatcher::NoHandlerAvailable)
      end
    end
  end

  describe "#dispatch_async" do
    let(:handler_class) { ExampleHandler }
    let(:event) { ExamplePerformedEevent.new }
    let(:event_handler_job) { instance_double("Jobs::EventsCore::EventHandlerJob") }

    before do
      allow(Jobs::EventsCore::EventHandlerJob)
        .to receive(:new).with(
          handler_klass: "ExampleHandler",
          event_klass: "ExamplePerformedEevent",
          payload: event.to_json
        ).and_return(event_handler_job)
    end

    context "when a handler is available" do
      it "enqueues event handler job" do
        expect(event_handler_job).to receive(:enqueue)
        described_class.dispatch_async(event)
      end
    end

    context "when no handler is available" do
      let(:unknown_event) { double("UnknownEvent", class: Class.new) }

      it "raises a NoHandlerAvailable error" do
        expect { described_class.dispatch_async(unknown_event) }.to raise_error(EventsCore::EventDispatcher::NoHandlerAvailable)
      end
    end
  end
end
