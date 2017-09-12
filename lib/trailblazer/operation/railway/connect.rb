module Trailblazer
  module Operation::Railway
    module Connect
      def connect(source_id, edge:raise, target:raise)
        id = "#{source_id}-#{edge}-#{target}"

        # FIXME: allow to no to railway
        wirings = Connect.(id, source: source_id, edge: [ edge, { id: id, type: :railway } ], target: target )

        add_element!( wirings, id: id ) # FIXME: right now, this goes into the Sequence.
      end

      # @return Array wirings
      def self.call(id, source:raise, edge:raise, target:raise)
        [
          [ :connect!, target: target, edge: edge, source: source ]
        ]
      end
    end
  end
end
