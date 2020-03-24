class PedagogicalTrackingController < ApplicationController
  def index
    last_refresh = MvwFrequencyBySchoolClassroomTeacher.first.last_refresh
    @updated_at = last_refresh.to_date.strftime('%d/%m/%Y')
    @updated_at_hour = last_refresh.hour

    @schools_percents = []

    fetch_all_school_days_by_unity

    @school_days = @all_school_days_by_unity.values.max

    @done_frequencies_percentage = total_frequency_done_percentage

    @done_content_records_percentage = total_content_record_done_percentage

    @all_school_days_by_unity.each { |unity_id, school_days|
      @schools_percents << OpenStruct.new(
        unity_name: Unity.find(unity_id).name,
        frequency_percentage: school_frequency_done_percentage(unity_id, school_days),
        content_record_percentage: school_content_record_done_percentage(unity_id, school_days)
      )
    }
  end

  private

  def unities
    @unities ||= Unity.ordered
  end
  helper_method :unities

  def unities_total
    @unities_total ||= @all_school_days_by_unity.size
  end

  def fetch_all_school_days_by_unity
    @all_school_days_by_unity = SchoolDaysCounterService.new(
      unities: unities,
      year: current_user_school_year
    ).all_school_days
  end

  def total_frequency_done_percentage
    percentage_sum = 0

    @all_school_days_by_unity.each do |unity_id, school_days|
      percentage_sum += school_frequency_done_percentage(unity_id, school_days)
    end

    percentage_sum / unities_total
  end

  def total_content_record_done_percentage
    percentage_sum = 0

    @all_school_days_by_unity.each do |unity_id, school_days|
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
