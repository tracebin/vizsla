require 'vizsla/recorder' unless defined?(::Vizsla::Recorder)

module Vizsla
  class Event
    attr_reader :event

    def initialize(event)
      @event = event
    end

    def recorder_type
      event[0]
    end

    def valid?
      true
    end

    def prettify_data
      {
        event_started: event[1],
        event_ended: event[2],
        event_duration: event[2] - event[1],
        event_payload: prettify_payload
      }
    end
  end

  class SQLEvent < Event
    def valid?
      event.last[:name] != "SCHEMA"
    end

    private

    def prettify_payload
      {
        query: event.last[:sql]
      }
    end
  end

  class ControllerEvent < Event
    private

    def prettify_payload
      payload = event.last
      {
        format: payload[:format],
        controller: payload[:controller],
        action: payload[:action],
        path: payload[:path],
        db_runtime: payload[:db_runtime]
      }
    end
  end

  class ViewEvent < Event
    private

    def prettify_payload
      {
        layout: event.last[:layout]
      }
    end
  end

  class Subscribers
    def initialize
      @events_data = Recorder
      # @logger = RequestLogger.new
      collect_events_data
    end

    def sql_hook
      ActiveSupport::Notifications.subscribe "sql.active_record" do |*args|
        event = SQLEvent.new(args)
        @events_data << event if event.valid?
      end
    end

    def process_action_hook
      ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
        event = ControllerEvent.new(args)
        @events_data << event
      end
    end

    def render_template_hook
      ActiveSupport::Notifications.subscribe "render_template.action_view" do |*args|
        event = ViewEvent.new(args)
        @events_data << event
      end
    end

    def collect_events_data
      sql_hook
      process_action_hook
      render_template_hook
    end

    def report_events_data
      @logger.log_events(@events_data)
    end
  end
end