class PedagogicalTrackingController < ApplicationController
  def index
    last_refresh = MvwFrequencyBySchoolClassroomTeacher.first.last_refresh
    @updated_at = last_refresh.to_date.strftime('%d/%m/%Y')
    @updated_at_hour = last_refresh.hour

    school_days_by_unity(current_user_school_year)

    @school_days = @school_days_by_unity.values.max

    @done_frequencies_percentage = total_frequency_done_percentage

    @done_content_records_percentage = total_content_record_done_percentage
  end

  private

  def unities
    @unities ||= Unity.ordered
  end
  helper_method :unities

  def unities_total
    @unities_total ||= @school_days_by_unity.size
  end

  def school_days_by_unity(year)
    @school_days_by_unity = Rails.cache.fetch('school_days_by_unity', expires_in: 1.year) {
      school_days_by_unity = {}

      unities.each do |unity|
        school_calendar = SchoolCalendar.by_year(year).by_unity_id(unity.id).first

        next if school_calendar.blank?

        start_date = school_calendar.steps.min_by(&:step_number).start_at
        end_date = school_calendar.steps.max_by(&:step_number).end_at

        school_days = SchoolDayChecker.new(
          school_calendar,
          start_date,
          nil,
          nil,
          nil
        ).school_dates_between(
          start_date,
          end_date
        ).size

        school_days_by_unity[unity.id] = school_days
      end

      school_days_by_unity
    }
  end

  def total_frequency_done_percentage
    percentage_sum = 0

    @school_days_by_unity.each do |unity_id, school_days|
      percentage_sum += school_frequency_done_percentage(unity_id, school_days)
    end

    percentage_sum / unities_total
  end

  def total_content_record_done_percentage
    percentage_sum = 0

    @school_days_by_unity.each do |unity_id, school_days|
      percentage_sum += school_content_record_done_percentage(unity_id, school_days)
    end

    percentage_sum / unities_total
  end

  def school_frequency_done_percentage(unity_id, school_days)
    done_frequencies = MvwFrequencyBySchoolClassroomTeacher.by_year(current_user_school_year)
                                                           .by_unity_id(unity_id)
                                                           .group_by(&:frequency_date)
                                                           .size

    (done_frequencies * 100) / school_days
  end

  def school_content_record_done_percentage(unity_id, school_days)
    done_content_records = MvwContentRecordBySchoolClassroomTeacher.by_year(current_user_school_year)
                                                                   .by_unity_id(unity_id)
                                                                   .group_by(&:record_date)
                                                                   .size
    (done_content_records * 100) / school_days
  end
end
