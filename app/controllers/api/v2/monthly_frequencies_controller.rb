module Api
  module V2
    class MonthlyFrequenciesController < Api::V2::BaseController
      before_action :authenticate_api!
      respond_to :json

      def index
        return if missing_required_params?
        return if invalid_months?

        render json: Api::MonthlyFrequenciesService.call(
          classrooms_api_code: params[:classrooms],
          year: params[:year],
          months: params[:months],
          students_api_code: params[:student_ids]
        ), root: false
      end

      private

      def missing_required_params?
        required_params = %i[classrooms year months]
        missing = required_params.select { |param| params[param].blank? }

        return false if missing.empty?

        render json: { error: "Os seguintes parâmetros são obrigatórios: #{missing.join(', ')}" },
               status: :unprocessable_entity
        true
      end

      def invalid_months?
        months = Array(params[:months]).map(&:to_i)

        return false if months.any? && months.all? { |m| m.between?(1, 12) }

        render json: { error: 'O parâmetro months deve conter apenas valores entre 1 e 12' },
               status: :unprocessable_entity
        true
      end
    end
  end
end
