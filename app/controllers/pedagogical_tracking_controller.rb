class PedagogicalTrackingController < ApplicationController
  def index
    last_refresh = MvwFrequencyBySchoolClassroomTeacher.first.last_refresh
    @updated_at = last_refresh.to_date.strftime('%d/%m/%Y')
    @updated_at_hour = last_refresh.hour

    unity_id = params.dig(:search, :unity_id).presence
    unity_id = nil if unity_id == 'empty'

    start_date = params.dig(:search, :start_date).presence
    end_date = params.dig(:search, :end_date).presence

    start_date = Date.strptime(start_date, '%d/%m/%Y') if start_date.present?
    end_date = Date.strptime(end_date, '%d/%m/%Y') if end_date.present?

    fetch_school_days_by_unity(unity_id, start_date, end_date)

    @school_days = @school_days_by_unity.values
                                        .max_by { |school_days_by_unity|
                                          school_days_by_unity[:school_days]
                                        }[:school_days]

    @done_frequencies_percentage = frequency_done_percentage

    @done_content_records_percentage = content_record_done_percentage

    @schools_percents = Kaminari.paginate_array(
      schools_percents(@school_days_by_unity)
    ).page(params[:page]).per(10)
  end

  private

  def all_unities
    @all_unities ||= Unity.joins(:school_calendars)
                          .where(school_calendars: { year: current_user_school_year })
                          .ordered
  end
  helper_method :all_unities

  def unities_total
    @unities_total ||= @school_days_by_unity.size
  end

  def fetch_school_days_by_unity(unity_id, start_date, end_date)
    unity = Unity.find(unity_id) if unity_id
    unities = unity || all_unities

    @school_days_by_unity = SchoolDaysCounterService.new(
      unities: unities,
      all_unities_size: all_unities.size,
      start_date: start_date,
      end_date: end_date,
      year: current_user_school_year
    ).school_days
  end

  def frequency_done_percentage
    percentage_sum = 0

    @school_days_by_unity.each do |unity_id, school_days|
      percentage_sum += school_frequency_done_percentage(
        unity_id,
        school_days[:start_date],
        school_days[:end_date],
        school_days[:school_days]
      )
    end

    return 0 if unities_total.zero?

    percentage_sum.to_f / unities_total
  end

  def content_record_done_percentage
    percentage_sum = 0

    @school_days_by_unity.each do |unity_id, school_days|
      percentage_sum += school_content_record_done_percentage(
        unity_id,
        school_days[:start_date],
        school_days[:end_date],
        school_days[:school_days]
      )
    end

    return 0 if unities_total.zero?

    percentage_sum.to_f / unities_total
  end

  def school_frequency_done_percentage(unity_id, start_date, end_date, school_days)
    done_frequencies = MvwFrequencyBySchoolClassroomTeacher.by_year(current_user_school_year)
                                                           .by_unity_id(unity_id)
                                                           .by_date_between(start_date, end_date)
                                                           .group_by(&:frequency_date)
                                                           .size

    (done_frequencies * 100).to_f / school_days
  end

  def school_content_record_done_percentage(unity_id, start_date, end_date, school_days)
    done_content_records = MvwContentRecordBySchoolClassroomTeacher.by_year(current_user_school_year)
                                                                   .by_unity_id(unity_id)
                                                                   .by_date_between(start_date, end_date)
                                                                   .group_by(&:record_date)
                                                                   .size
    (done_content_records * 100).to_f / school_days
  end

  def schools_percents(school_days_by_unity)
    schools_percents = []

    school_days_by_unity.each { |unity_id, school_days|
      unity = Unity.find(unity_id)
      frequency_percentage = school_frequency_done_percentage(
        unity_id,
        school_days[:start_date],
        school_days[:end_date],
        school_days[:school_days]
      )
      content_record_percentage = school_content_record_done_percentage(
        unity_id,
        school_days[:start_date],
        school_days[:end_date],
        school_days[:school_days]
      )

      schools_percents << OpenStruct.new(
        unity: unity,
        frequency_percentage: frequency_percentage,
        content_record_percentage: content_record_percentage
      )
    }

    schools_percents
  end
end
