module Capybara
  module RSpecMatchers
    class HaveSelect2 < Matcher
      attr_reader :matching_value

      def initialize(*args)
        @locator = args.first
        @matching_value = args.last[:with]
      end

      def matches?(actual)
        actual.has_field? @locator
      end

      def does_not_match?(actual)
        actual.has_field? @locator
      end

      def failure_message_for_should
        "expected to exist"
      end

      def failure_message_for_should_not
        "expected to not exist"
      end

      def description
        "select2 input existence"
      end
    end
  end
end