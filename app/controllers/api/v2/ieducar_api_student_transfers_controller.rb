# frozen_string_literal: true

module Api
  module V2
    class IeducarApiStudentTransfersController < Api::V2::BaseController
      respond_to :json

      def create
        validate_params!

        IeducarStudentTransferPostingWorker.perform_async(
          current_entity.id,
          student.id,
          classroom.id,
          params[:callback_url]
        )

        render json: { status: 'processing' }, status: :accepted
      rescue ActiveRecord::RecordNotFound => e
        render json: { error: 'Matrícula não encontrada' }, status: :not_found
      rescue ArgumentError => e
        render json: { error: e.message }, status: :bad_request
      end

      private

      def validate_params!
        required = %i[student_enrollment_api_code callback_url]
        missing = required.select { |param| params[param].blank? }

        return if missing.empty?

        raise ArgumentError, "Parâmetros obrigatórios: #{missing.join(', ')}"
      end

      def student_enrollment_classroom
        @student_enrollment_classroom ||= StudentEnrollmentClassroom
          .joins(:student_enrollment)
          .find_by!(student_enrollments: { api_code: params[:student_enrollment_api_code] })
      end

      def student
        @student ||= student_enrollment_classroom.student_enrollment.student
      end

      def classroom
        @classroom ||= student_enrollment_classroom.classrooms_grade.classroom
      end

      def current_entity
        @current_entity ||= Entity.find_by!(domain: request.host)
      end
    end
  end
end
