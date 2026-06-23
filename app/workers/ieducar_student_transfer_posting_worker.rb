# frozen_string_literal: true

class IeducarStudentTransferPostingWorker
  include Sidekiq::Worker

  sidekiq_options queue: :critical,
                  retry: 3,
                  unique: :until_and_while_executing,
                  unique_args: ->(args) { args },
                  dead: false,
                  on_conflict: { client: :log, server: :reject }

  # Disparado pelo Sidekiq após todas as retries terem falhado.
  # Envia um único callback de erro com a mensagem técnica da última exceção,
  # evitando que o consumidor receba uma notificação a cada tentativa.
  sidekiq_retries_exhausted do |msg, exception|
    entity_id, student_id, _classroom_id, callback_url = msg['args']

    Entity.find(entity_id).using_connection do
      student = Student.find_by(id: student_id)
      api_code = StudentEnrollment.find_by(student: student)&.api_code
      token = IeducarApiConfiguration.current&.api_security_token

      payload = {
        status: 'error',
        student_enrollment_api_code: api_code,
        message: I18n.t(
          'ieducar_student_transfer_posting_worker.callback_messages.exception_failure',
          name: student&.name.presence || 'aluno'
        ),
        error: exception.message
      }

      headers = { content_type: :json }
      headers[:token] = token if token.present?

      RestClient.post(callback_url, payload.to_json, headers) if callback_url.present?
    rescue StandardError => e
      # Falha do callback HTTP não deve impedir Honeybadger.notify da exceção original
      Rails.logger.error(
        "IeducarStudentTransferPostingWorker: Failed to notify exception failure - #{e.message}"
      )
    end

    Honeybadger.notify(exception)
  end

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
