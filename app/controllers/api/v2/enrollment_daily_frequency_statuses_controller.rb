module Api
  module V2
    class EnrollmentDailyFrequencyStatusesController < Api::V2::BaseController
      before_action :authenticate_api!
      respond_to :json

      def index
        return if missing_required_params?
        return if invalid_period?
        return if invalid_limit?

        render json: Api::EnrollmentDailyFrequencyStatusesService.call(
          student_enrollment_api_code: params[:student_enrollment_id],
          start_at: start_at,
          end_at: end_at,
          limit: limit
        ), root: false
      end

      private

      def missing_required_params?
        return false if params[:student_enrollment_id].present?

        render json: { error: 'Os seguintes parâmetros são obrigatórios: student_enrollment_id' },
               status: :unprocessable_entity
        true
      end

      def invalid_period?
        if invalid_date_param?(:start_at) || invalid_date_param?(:end_at)
          render json: { error: 'Os parâmetros start_at e end_at devem estar no formato AAAA-MM-DD' },
                 status: :unprocessable_entity
          return true
        end

        if start_at && end_at && start_at > end_at
          render json: { error: 'O parâmetro start_at deve ser anterior ou igual a end_at' },
                 status: :unprocessable_entity
          return true
        end

        false
      end

      def invalid_date_param?(param)
        params[param].present? && parse_iso_date(params[param]).nil?
      end

      def invalid_limit?
        return false if params[:limit].blank?
        return false if limit

        render json: { error: 'O parâmetro limit deve ser um número inteiro maior que zero' },
               status: :unprocessable_entity
        true
      end

      def limit
        return @limit if defined?(@limit)

        value = params[:limit].to_s
        @limit = value =~ /\A\d+\z/ && value.to_i.positive? ? value.to_i : nil
      end

      def start_at
        @start_at ||= parse_iso_date(params[:start_at])
      end

      def end_at
        @end_at ||= parse_iso_date(params[:end_at])
      end

      def parse_iso_date(value)
        Date.iso8601(value.to_s)
      rescue ArgumentError
        nil
      end
    end
  end
end
