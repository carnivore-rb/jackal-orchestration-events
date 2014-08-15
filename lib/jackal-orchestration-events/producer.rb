require 'fog'
require 'digest/sha2'
require 'jackal-orchestration-events'

module Jackal
  module OrchestrationEvents
    # Generate event artifacts from orchestration stacks
    class Producer

      include Celluloid

      # default interval between API poll
      DEFAULT_POLL_INTERVAL = 30

      # @return [Fog::Orchestration]
      attr_reader :connection

      # @return [String]
      attr_reader :cache_directory

      # Create new event producer
      #
      # @param args [Hash]
      # @option args [Hash] :credentials Fog credential hash
      # @option args [Numeric] :interval Interval between poll
      # @option args [TrueClass, FalseClass] :auto_start start polling
      # @option args [String, Symbol] :send_to name of source to send events
      # @option args [String] :cache path to cache directory
      # @note will auto_start by default
      def initialize(args={})
        args = args.to_smash
        unless(args[:credentials])
          raise ArgumentError.new '`:credentials` are required for API connection'
        end
        unless(args[:send_to])
          raise ArgumentError.new '`:send_to` is required for message distribution'
        end
        @connection = Fog::Orchestration.new(args[:credentials])
        @cache_id = Digest::SHA256.hexdigest(
          args[:credentials].to_a.flatten.map(&:to_s).sort.join
        )
        @poller = nil
        @source_name = args[:send_to]
        @cache_directory = args.fetch(:cache, '/tmp')
        seed_events
        if(args.fetch(:auto_start, true))
          unpause
        end
      end

      # Pause polling
      #
      # @return [TrueClass]
      def pause
        if(@poller)
          @poller.cancel
          @poller = nil
        end
        true
      end

      # Unpause polling
      #
      # @return [TrueClass]
      def unpause
        unless(@poller)
          @poller = every(@interval){ poll }
        end
        true
      end

      # @return [Carnivore::Source]
      def send_to
        Carnivore::Supervisor.supervisor[@source_name]
      end

      # @return [String] path to cache file
      def cache_file
        File.join(cache_directory, @cache_id)
      end

      private

      # Poll for events
      def poll
        result = fetch_events
        diff_and_cache(result).each do |event|
          send_to.transmit(event)
        end
      end

      # Detect state changes against current seed. Store
      # new state
      #
      # @param state [Smash]
      # @return [Array<Hash>]
      def diff_and_cache(state)
        change_stacks = (@seed.keys + state.keys).uniq.map do |stack_id|
          stack = @connection.stacks.get(stack_id)
          if(@seed.fetch(stack_id, :stack_status) != state.fetch(stack_id, :stack_status))
            stack_status = stack ? stack.stack_status : 'DELETE_COMPLETE'
            Smash.new(
              :stack_id => stack_id,
              :stack_name => stack.stack_name,
              :event_id => Celluloid.uuid,
              :logical_resource_id => stack.stack_name,
              :physical_resource_id => stack_id,
              :timestamp => Time.now.iso8601,
              :resource_type => 'AWS::CloudFormation::Stack',
              :resource_status => stack_status
            )
          end
        end.compact
        new_events = state.each do |stack_id, info|
          events = info[:events] - @seed[stack_id][:events]
        end.flatten(1)
        @seed = state
        save_seed
        change_stacks + new_events
      end

      # Fetch events from all active stacks
      #
      # @return [Smash]
      def fetch_events
        Smash[
          @connection.stacks.reload.map do |stack|
            [stack.stack_id,
              Smash.new(
                :events => stack.events,
                :status => stack.stack_status
              )
            ]
          end
        ]
      end

      # Initialize the local seed and load data from cache
      # file if it exists
      #
      # @return [Smash]
      def load_seed
        if(File.exists?(cache_file))
          @seed = MultiJson.load(File.read(cache_file)).to_smash
        else
          @seed = fetch_events
        end
      end

      # Save seed to cache file
      #
      # @return [TrueClass]
      def save_seed
        File.open(cache_file, 'w') do |file|
          file.puts MultiJson.dump(@seed)
        end
        true
      end

    end
  end
end
