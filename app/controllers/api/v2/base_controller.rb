module Api
  module V2
    class BaseController < Api::V1::BaseController
      private

      def set_thread_origin_type
        Thread.current[:origin_type] = OriginTypes::API_V2
        begin
          yield
        ensure
          Thread.current[:origin_type] = nil
        end
      end
    end
  end
end
