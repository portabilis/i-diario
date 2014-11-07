module Navigation
  module Render
    class Base
      def initialize(context)
        @context = context
      end

      def path_method(method)
        return "#" unless method
        context.send(method)
      end

      protected

      attr_reader :context

      delegate :raw, :content_tag, :link_to, :to => :context
    end
  end
end
