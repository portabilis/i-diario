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
    @student_api_code = nil
    @classroom_api_code = nil

    Entity.find(entity_id).using_connection do
      student = Student.find(student_id)
      classroom = Classroom.find(classroom_id)

      @student_api_code = student.api_code
      @classroom_api_code = classroom.api_code

      fetcher = IeducarStudentTransferDataFetcher.new(
        student: student,
        classroom: classroom
      )

      fetcher.post_to_ieducar!

      send_confirmation_webhook('success')
    end
  rescue StandardError => e
    send_confirmation_webhook('error', e.message)

    raise e
  end

  private

  def send_confirmation_webhook(status, error_message = nil)
    return if @callback_url.blank?

    payload = {
      status: status,
      student_id: @student_api_code,
      classroom_id: @classroom_api_code
    }

    payload[:error] = error_message if error_message.present?

    RestClient.post(@callback_url, payload.to_json, content_type: :json)
  rescue StandardError => e
    Rails.logger.error(
      "IeducarStudentTransferPostingWorker: Failed to send confirmation webhook - #{e.message}"
    )
  end
end
