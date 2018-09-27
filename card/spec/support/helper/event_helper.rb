class Card
  module SpecHelper
    module EventHelper
      # Make expectations in the event phase.
      # Takes a stage and registers the event_block in this stage as an event.
      # Unknown methods in the event_block are executed in the rspec context
      # instead of the card's context.
      # An additionally :trigger block in opts is expected that is called
      # to start the event phase.
      # You can restrict the event to a specific card by passing a name
      # with :for options.
      # That's for example necessary if you create a card in a event.
      # Otherwise you get a loop of card creations.
      # @example
      #   in_stage :initialize,
      #            for: "my test card",
      #            trigger: -> { test_card.update_attributes! content: '' } do
      #     expect(item_names).to eq []
      #   end
      def in_stage stage, opts={}, &event_block
        Card.rspec_binding = binding
        trigger = opts.delete(:trigger)
        trigger = method(trigger) if trigger.is_a?(Symbol)
        add_test_event stage, :in_stage_test, opts, &event_block
        ensure_clean_up stage do
          trigger.call
        end
      end

      def ensure_clean_up stage
        yield
      ensure
        remove_test_event stage, :in_stage_test
      end

      def create_with_event name, stage, opts={}, &event_block
        in_stage stage, opts.merge(for: name, trigger: -> { create name }), &event_block
      end

      # if you need more then one test event (otherwise use #in_stage)
      # @example
      #   with_test_events do
      #     test_event :store, for: "my card" do
      #        Card.create name: "other card"
      #     end
      #     test_event :finalize, for: "other card" do
      #        expect(content).to be_empty
      #     end
      #   end
      def with_test_events
        @events = []
        Card.rspec_binding = binding
        yield
      ensure
        @events.each do |stage, name|
          remove_test_event stage, name
        end
        Card.rspec_binding = false
      end

      def test_event stage, opts={}, &block
        event_name = :"test_event_#{@events.size}"
        @events << [stage, event_name]
        add_test_event stage, event_name, opts, &block
      end

      def add_test_event stage, name, opts={}, &event_block
        # use random set module that is always included so that the
        # event applies to all cards
        set_module = opts.delete(:set) || Card::Set::All::Fetch
        if (only_for_card = opts.delete(:for))
          opts[:when] = proc { |c| c.name == only_for_card }
        end
        Card::Set::Event.new(name, stage, opts, set_module, &event_block).register
      end

      def remove_test_event stage, name
        stage_sym = :"#{stage}_stage"
        Card.skip_callback stage_sym, :after, name
      end

      # Turn delayed jobs on and run jobs after the given block.
      # If count is given check if it matches the number of created jobs.
      def with_delayed_jobs count=nil
        Delayed::Worker.delay_jobs = true
        expect(Delayed::Job.count).to eq(0), "expected delayed job to start with an empty queue"
        yield
        if count
          expect(Delayed::Job.count)
            .to eq(count), "expected jobs: #{count}\n"\
                           "          got: #{Delayed::Job.count}\n"\
                           "#{Delayed::Job.all.map(&:queue).join ', '}"
        end
        Delayed::Worker.new.work_off
        expect(Delayed::Job.count).to eq(0), "not all delayed jobs were executed: #{Delayed::Job.last&.last_error}"
        Delayed::Worker.delay_jobs = false
      end
    end
  end
end
