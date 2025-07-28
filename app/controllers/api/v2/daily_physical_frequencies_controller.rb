module Api
  module V2
    class DailyPhysicalFrequenciesController < Api::V2::BaseController
      before_action :authenticate_api!

      def create
        unity = Unity.find_by(api_code: daily_physical_frequency_params[:unity_api_code])
        student_enrollment = StudentEnrollment.find_by(api_code: daily_physical_frequency_params[:student_enrollment_api_code])

        if unity.nil?
          return render json: { errors: ["Unidade com api_code #{daily_physical_frequency_params[:unity_api_code]} não encontrada."] }, status: :unprocessable_entity
        end

        if student_enrollment.nil?
          return render json: { errors: ["Matrícula com api_code #{daily_physical_frequency_params[:student_enrollment_api_code]} não encontrada."] }, status: :unprocessable_entity
        end

        daily_physical_frequency = DailyPhysicalFrequency.new(
          unity_id: unity.id,
          student_enrollment_id: student_enrollment.id,
          frequency_date: daily_physical_frequency_params[:frequency_date],
          present: daily_physical_frequency_params[:present]
        )

        if daily_physical_frequency.save
          render json: { status: 'success', data: daily_physical_frequency }, status: :created
        else
          render json: { errors: daily_physical_frequency.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def daily_physical_frequency_params
        params.require(:daily_physical_frequencies).permit(
          :unity_api_code,
          :student_enrollment_api_code,
          :frequency_date,
          :present
        )
      end
    end
  end
end

