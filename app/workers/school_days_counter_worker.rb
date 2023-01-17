class SchoolDaysCounterWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(entity_id, school_calendar_id)
    Entity.find(entity_id).using_connection do
      school_calendar = SchoolCalendar.find(school_calendar_id)

      return if school_calendar.steps.empty?

      start_date = school_calendar.steps.min_by(&:step_number).start_at
      end_date = school_calendar.steps.max_by(&:step_number).end_at

      current_school_days = UnitySchoolDay.by_unity_id(school_calendar.unity_id)
                                          .where('EXTRACT(YEAR FROM school_day) = ?', school_calendar.year)
                                          .pluck(:school_day)

      school_days = SchoolDayChecker.new(
        school_calendar,
        start_date.to_date,
        nil,
        nil,
        nil
      ).school_dates_between(
        start_date.to_date,
        end_date.to_date
      )

      school_days_to_removes = (current_school_days - school_days)

      UnitySchoolDay.where(school_day: school_days_to_removes).destroy_all

      school_days.each do |school_day|
        UnitySchoolDay.find_or_create_by!(unity_id: school_calendar.unity_id, school_day: school_day)
      end
    end
  end
end
