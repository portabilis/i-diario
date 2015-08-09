module Capybara
  module RSpecMatchers
    class HaveSelect2Filled < Matcher
      attr_reader :locator, :matching_value, :select2_choice

      def initialize(*args)
        @locator = args.first
        @matching_value = args.last[:with]
      end

      def matches?(actual)
        set_select2_choice actual

        select2_choice == matching_value
      end

      def does_not_match?(actual)
        set_select2_choice actual

        select2_choice != matching_value
      end

      def failure_message
        "expected #{matching_value.inspect} to be equals to #{select2_choice}"
      end

      def failure_message_when_negated
        "expected #{matching_value.inspect} to not be equals to #{select2_choice}"
      end

      def description
        "select2 input that has value #{format(content)}"
      end

      private

      def set_select2_choice(actual)
        actual.has_field? locator

        field = actual.find_field locator

        @select2_choice = field.find(:xpath, '..').find(".select2-chosen").text
      end
    end
  end
end
