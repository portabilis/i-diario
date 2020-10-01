class SchoolCalendarEventBatchCreatorWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(entity_id, school_calendar_event_batch_id)
    Entity.find(entity_id).using_connection do
      begin
        school_calendar_event_batch = SchoolCalendarEventBatch.find(school_calendar_event_batch_id)

        SchoolCalendar.by_year(school_calendar_event_batch.year).each do |school_calendar|
          begin
            SchoolCalendarEvent.find_or_create_by!(
              school_calendar_id: school_calendar.id,
              description: school_calendar_event_batch.description,
              start_date: school_calendar_event_batch.start_date,
              end_date: school_calendar_event_batch.end_date,
              event_type: school_calendar_event_batch.event_type,
              legend: school_calendar_event_batch.legend,
              show_in_frequency_record: school_calendar_event_batch.show_in_frequency_record,
              batch_id: school_calendar_event_batch.id
            )
          rescue ActiveRecord::RecordInvalid => error
            next
          end
        end

        school_calendar_event_batch.update(batch_status: BatchStatus::COMPLETED)
      rescue StandardError => error
        school_calendar_event_batch.mark_with_error!(error.message)
      end
    end
  end
end
