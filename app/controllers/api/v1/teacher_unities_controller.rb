module Api
  module V1
    class TeacherUnitiesController < Api::V1::BaseController
      respond_to :json

      def index
        return unless params[:teacher_id]

        @unities = Unity.by_teacher(params[:teacher_id]).ordered.uniq
      end
    end
  end
end
