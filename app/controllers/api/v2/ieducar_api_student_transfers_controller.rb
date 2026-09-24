# frozen_string_literal: true

module Api
  module V2
    class IeducarApiStudentTransfersController < Api::V2::BaseController
      class InvalidParamsError < StandardError; end

      respond_to :json

      def create
        validate_params!
        transfer_date = parse_transfer_date!

        assignments = active_classroom_assignments
        raise ActiveRecord::RecordNotFound if assignments.empty?

        assignments.each do |student_id, classroom_id|
          IeducarStudentTransferPostingWorker.perform_async(
            current_entity.id,
            student_id,
            classroom_id,
            params[:callback_url],
            transfer_date
          )
        end

        render json: { status: 'processing' }, status: :accepted
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Matrícula não encontrada' }, status: :not_found
      rescue InvalidParamsError => e
        render json: { error: e.message }, status: :bad_request
      end

      private

      def validate_params!
        required = %i[student_enrollment_api_code callback_url]
        missing = required.select { |param| params[param].blank? }

        return if missing.empty?

        raise InvalidParamsError, "Parâmetros obrigatórios: #{missing.join(', ')}"
      end

      # transfer_date é opcional, mas quando informado precisa estar em ISO-8601
      # (YYYY-MM-DD). A validação é feita de forma síncrona para que uma data
      # inválida vire um 400 explícito, em vez de ser descoberta só no worker
      # assíncrono — onde a falha desabilitaria silenciosamente o filtro da
      # última etapa. Parse estrito evita datas ambíguas (ex.: "07/06/2026").
      def parse_transfer_date!
        raw = params[:transfer_date]
        return if raw.blank?

        Date.iso8601(raw.to_s).iso8601
      rescue ArgumentError
        raise InvalidParamsError, 'transfer_date inválida: utilize o formato ISO-8601 (YYYY-MM-DD)'
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
