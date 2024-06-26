module Api
  module V2
    class TeachingPlansController < Api::V2::BaseController
      respond_to :json

      def index
        return unless params[:teacher_id]

        @unities = Unity.by_teacher(params[:teacher_id]).ordered.distinct
        @unities = @unities.select do |unity|
          TeachingPlan.by_unity_id(unity.id).exists?
        end
        @teacher_id = params[:teacher_id]
      end
    end
  end
end
