class PopulateUnitySchoolDays < ActiveRecord::Migration
  def change
    SchoolCalendar.all.each do |school_calendar|
      start_date = school_calendar.steps.min_by(&:step_number).start_at
      end_date = school_calendar.steps.max_by(&:step_number).end_at

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

      school_days.each do |school_day|
        UnitySchoolDay.find_or_create_by!(unity_id: school_calendar.unity_id, school_day: school_day)
      end
    end
  end
end
