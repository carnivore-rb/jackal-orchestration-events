require 'jackal-orchestration-events'

module Jackal
  module OrchestrationEvents
    # Poll orchestration API for events
    class Poll < Jackal::Callback

      trap_exit :producer_failure

      # @return [Array<Producer>]
      attr_reader :producers
      # @return [Array<Hash>]
      attr_reader :api_configs

      # Build event producers
      def setup
        @api_configs = [config[:apis]].flatten
        @producers = api_configs.each do |creds|
          build_producer(creds)
        end
      end

      # Build a new producer and link to this instance
      #
      # @param creds [Hash] fog credentials
      # @return [Producer]
      def build_producer(creds)
        producer = Producer.new(
          :credentials => creds,
          :send_to => self.name
        )
        self.link producer
        producer
      end

      # Handle failed producers
      #
      # @param actor [Object] terminated actor
      # @param reason [Exception] reason for termination
      # @return [NilClass]
      def producer_failure(actor, reason)
        idx = producers.index(actor)
        producers.delete_at(idx)
        producers.insert(idx, build_producer(api_configs[idx]))
        nil
      end

      # @return [TrueClass] messages always valid
      def valid?(*_)
        true
      end

      # Forward events into pipeline
      #
      # @param message [Carnivore::Message]
      def execute(message)
        failure_wrap(message) do |event|
          new_payload(
            config[:name],
            :cfn_event => event
          )
          completed(event, message)
        end
      end

    end
  end
end
