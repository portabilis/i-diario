module Capybara
  module RSpecMatchers
    class HaveSelect2Disabled < Matcher
      attr_reader :matching_value

      def initialize(*args)
        @locator = args.first
        @matching_value = args.last[:with]
      end

      def matches?(actual)
        actual.has_field? @locator, :disabled => true
      end

      def does_not_match?(actual)
        actual.has_field? @locator, :disabled => true
      end

      def failure_message_for_should
        "expected to be disabled"
      end

      def failure_message_for_should_not
        "expected to not be disabled"
      end

      def description
        "select2 input that is disabled"
      end
    end
  end
end