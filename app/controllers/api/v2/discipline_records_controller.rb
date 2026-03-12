# frozen_string_literal: true

module Api
  module V2
    # API endpoints for counting and destroying discipline records in batch
    class DisciplineRecordsController < Api::V2::BaseController
      def count
        return render_missing_params(FILTER_PARAMS) unless params_present?(FILTER_PARAMS)

        counter = Api::DisciplineRecordsCounter.new(**record_params)
        render json: counter.call, root: false
      end

      def destroy_batch
        return render_missing_params(DESTROY_PARAMS) unless params_present?(DESTROY_PARAMS)

        deletion = DisciplineRecordDeletion.create!(
          filters: build_filters,
          status: DisciplineRecordDeletionStatus::PROCESSING,
          operation_id: params[:operation_id]
        )

        DisciplineRecordsDestroyerWorker.perform_async(
          current_entity.id,
          deletion.id
        )

        render json: { queued: true }
      end

      private

      FILTER_PARAMS = %i[year unities courses grades disciplines].freeze
      DESTROY_PARAMS = (FILTER_PARAMS + %i[user]).freeze

      def build_filters
        {
          year: params[:year].to_i,
          unities_api_code: params[:unities],
          courses_api_code: params[:courses],
          grades_api_code: params[:grades],
          disciplines_api_code: params[:disciplines],
          user_api_code: params[:user].to_s
        }
      end

      def params_present?(required)
        required.all? { |p| Array(params[p]).reject(&:blank?).present? }
      end

      def record_params
        {
          unities: params[:unities],
          courses: params[:courses],
          grades: params[:grades],
          disciplines: params[:disciplines],
          year: params[:year]
        }
      end

      def render_missing_params(required)
        missing = required.select { |p| Array(params[p]).reject(&:blank?).blank? }.join(', ')
        render json: { success: false, errors: "Parâmetros obrigatórios ausentes: #{missing}" },
               status: :unprocessable_entity
      end
    end
  end
end
