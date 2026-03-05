# frozen_string_literal: true

module Api
  module V2
    # API endpoints for counting and destroying discipline records in batch
    class DisciplineRecordsController < Api::V2::BaseController
      def count
        return render_missing_year unless params[:year].present?

        counter = Api::DisciplineRecordsCounter.new(**record_params)
        render json: counter.call, root: false
      end

      def destroy_batch
        return render_missing_year unless params[:year].present?

        destroyer = Api::DisciplineRecordsDestroyer.new(**record_params)
        total = destroyer.call

        render json: { success: true, deleted: total }
      rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::StatementInvalid, ActiveRecord::RecordInvalid => e
        Honeybadger.notify(e)
        render json: { success: false, errors: e.message }, status: :unprocessable_entity
      end

      private

      def record_params
        {
          unities: params[:unities],
          courses: params[:courses],
          grades: params[:grades],
          disciplines: params[:disciplines],
          year: params[:year]
        }
      end

      def render_missing_year
        render json: { success: false, errors: 'O parâmetro year é obrigatório' },
               status: :unprocessable_entity
      end
    end
  end
end
