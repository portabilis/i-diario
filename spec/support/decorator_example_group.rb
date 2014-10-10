require 'active_support/concern'

module RSpec
  module Decorator
    module DecoratorExample***REMOVED***
      extend ActiveSupport::Concern

      included do
        metadata[:type] = :decorator

        subject do
          described_class.new(component)
        end

        before do
          subject.stub(:routes).and_return(routes) if subject.respond_to?(:routes)
        end

        let :component do
          double(:component)
        end

        let :routes do
          double(:routes)
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Decorator::DecoratorExample***REMOVED***, :type => :decorator, :example_group => {
    :file_path => /spec[\\\/]decorators/
  }
end
