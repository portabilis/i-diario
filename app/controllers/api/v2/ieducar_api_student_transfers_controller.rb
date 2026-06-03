# frozen_string_literal: true

module Api
  module V2
    class IeducarApiStudentTransfersController < Api::V2::BaseController
      respond_to :json

      def create
        validate_params!

        assignments = active_classroom_assignments
        raise ActiveRecord::RecordNotFound if assignments.empty?

        assignments.each do |student_id, classroom_id|
          IeducarStudentTransferPostingWorker.perform_async(
            current_entity.id,
            student_id,
            classroom_id,
            params[:callback_url]
          )
        end

        render json: { status: 'processing' }, status: :accepted
      rescue ActiveRecord::RecordNotFound
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

      def active_classroom_assignments
        StudentEnrollmentClassroom
          .joins(:student_enrollment, classrooms_grade: :classroom)
          .where(student_enrollments: { api_code: params[:student_enrollment_api_code] })
          .where("COALESCE(student_enrollment_classrooms.left_at, '') = ''")
          .pluck('student_enrollments.student_id', 'classrooms_grades.classroom_id')
      end

      def current_entity
        @current_entity ||= Entity.find_by!(domain: request.host)
      end
    end
  end
end
