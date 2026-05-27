# frozen_string_literal: true

class IeducarStudentTransferPostingWorker
  include Sidekiq::Worker

  sidekiq_options queue: :critical,
                  retry: 3,
                  unique: :until_and_while_executing,
                  unique_args: ->(args) { args },
                  dead: false,
                  on_conflict: { client: :log, server: :reject }

  def perform(entity_id, student_id, classroom_id, callback_url)
    @callback_url = callback_url
    @student_enrollment_api_code = nil
    @student_name = nil

    Entity.find(entity_id).using_connection do
      student = Student.find(student_id)
      @student_name = student.name
      classroom = Classroom.find(classroom_id)

      student_enrollment = StudentEnrollment.find_by!(student: student)
      @student_enrollment_api_code = student_enrollment.api_code
      @api_security_token = IeducarApiConfiguration.current.api_security_token

      fetcher = IeducarStudentTransferDataFetcher.new(
        student: student,
        classroom: classroom
      )

      fetcher.post_to_ieducar!

      if fetcher.all_postings_sent
        send_confirmation_webhook(status: 'success', message_key: 'success')
      else
        send_confirmation_webhook(status: 'error', message_key: 'partial_failure')
      end
    end
  rescue StandardError => e
    send_confirmation_webhook(status: 'error', message_key: 'exception_failure', error_message: e.message)

    raise e
  end

  private

  def send_confirmation_webhook(status:, message_key:, error_message: nil)
    return if @callback_url.blank?

    payload = {
      status: status,
      student_enrollment_api_code: @student_enrollment_api_code,
      message: build_message(message_key)
    }

    payload[:error] = error_message if error_message.present?

    headers = { content_type: :json }
    headers[:token] = @api_security_token if @api_security_token.present?

    RestClient.post(@callback_url, payload.to_json, headers)
  rescue StandardError => e
    Rails.logger.error(
      "IeducarStudentTransferPostingWorker: Failed to send confirmation webhook - #{e.message}"
    )
  end

  def build_message(message_key)
    I18n.t(
      "ieducar_student_transfer_posting_worker.callback_messages.#{message_key}",
      name: @student_name.presence || 'aluno',
      default: nil
    )
  end
end
