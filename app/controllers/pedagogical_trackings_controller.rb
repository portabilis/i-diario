class PedagogicalTrackingsController < ApplicationController
  before_action :require_current_year
  before_action :minimum_year

  def index
    if (last_refresh = MvwFrequencyBySchoolClassroomTeacher.first&.last_refresh ||
                       MvwContentRecordBySchoolClassroomTeacher.first&.last_refresh)

      @updated_at = last_refresh.to_date.strftime('%d/%m/%Y')
      @updated_at_hour = last_refresh.hour
    end

    employee_unity = employee_unities.first.id if employee_unities.presence&.one?
    unity_id = params.dig(:search, :unity_id).presence || params[:unity_id] || employee_unity

    @start_date = params.dig(:search, :start_date).presence
    start_date = (@start_date || params[:start_date]).try(:to_date)

    @end_date = params.dig(:search, :end_date).presence
    end_date = (@end_date || params[:end_date]).try(:to_date)

    fetch_school_days_by_unity(unity_id, start_date, end_date)

    @school_days = @school_days_by_unity.values
                                        .max_by { |school_days_by_unity|
                                          school_days_by_unity[:school_days]
                                        }[:school_days]
    @school_frequency_done_percentage = school_frequency_done_percentage
    @school_content_record_done_percentage = school_content_record_done_percentage
    @unknown_teachers = school_unknown_teacher_frequency_done_percentage
    @partial = :schools

    @percents = if unity_id
                  @partial = :classrooms
                  @classrooms = Classroom.where(unity_id: unity_id, year: current_user_school_year).ordered

                  paginate(filter(percents(@classrooms.pluck(:id)), params.dig(:filter)))
                else
                  paginate(filter(percents, params.dig(:filter)))
                end
  end

  def recalculate

    school_calendars = SchoolCalendar.ids

    school_calendars.each do |school_calendar_id|

    SchoolDaysCounterWorker.perform_async(@current_entity.id, school_calendar_id)
    end

    redirect_to pedagogical_trackings_path
  end

  def teachers
    unity_id = params[:unity_id]
    classroom_id = params[:classroom_id]
    teacher_id = params[:teacher_id]
    start_date = params[:start_date].try(:to_date)
    end_date = params[:end_date].try(:to_date)

    fetch_school_days_by_unity(unity_id, start_date, end_date)

    teachers_ids = [teacher_id].compact.presence ||
                   Teacher.by_classroom(classroom_id).by_year(current_user_school_year).pluck(:id).uniq

    @teacher_percents = []

    teachers_ids.each do |teacher_id|
      @teacher_percents << percents([params[:classroom_id]], teacher_id)
    end

    @teacher_percents = @teacher_percents.flatten

    filter_params = params.slice(
      :frequency_operator,
      :frequency_percentage,
      :content_record_operator,
      :content_record_percentage
    )

    @teacher_percents = filter(@teacher_percents, filter_params)

    respond_with @teacher_percents
  end

  private

  def minimum_year
    return if current_user_school_year >= 2020

    flash[:alert] = t('pedagogical_trackings.minimum_year.error')

    redirect_to root_path
  end

  def employee_unities
    return unless current_user.employee?

    roles_ids = Role.where(access_level: AccessLevel::EMPLOYEE).pluck(:id)
    unities_ids = UserRole.where(user_id: current_user.id, role_id: roles_ids).pluck(:unity_id)
    @employee_unities ||= Unity.find(unities_ids)
  end
  helper_method :employee_unities

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
    unities = unity || employee_unities || all_unities

    @school_days_by_unity = SchoolDaysCounterService.new(
      unities: unities,
      all_unities_size: all_unities.size,
      start_date: start_date,
      end_date: end_date,
      year: current_user_school_year
    ).school_days
  end

  def school_frequency_done_percentage
    percentage_sum = 0

    @school_days_by_unity.each do |unity_id, school_days|
      percentage_sum += frequency_done_percentage(
        unity_id,
        school_days[:start_date],
        school_days[:end_date],
        school_days[:school_days]
      )
    end

    return 0 if unities_total.zero?

    (percentage_sum.to_f / unities_total).round(2)
  end

  def school_unknown_teacher_frequency_done_percentage
    unknown_teacher_percentage_sum = 0

    @school_days_by_unity.each do |unity_id, school_days|
      unknown_teacher_percentage_sum += unknown_teacher_frequency_done(
        unity_id,
        school_days[:start_date],
        school_days[:end_date],
        school_days[:school_days]
      )
    end

    return 0 if unities_total.zero?

    (unknown_teacher_percentage_sum.to_f / unities_total).round(2)
  end

  def school_content_record_done_percentage
    percentage_sum = 0

    @school_days_by_unity.each do |unity_id, school_days|
      percentage_sum += content_record_done_percentage(
        unity_id,
        school_days[:start_date],
        school_days[:end_date],
        school_days[:school_days]
      )
    end

    return 0 if unities_total.zero?

    (percentage_sum.to_f / unities_total).round(2)
  end

  def frequency_done_percentage(
    unity_id,
    start_date,
    end_date,
    school_days,
    classroom_id = nil,
    teacher_id = nil
  )
    @done_frequencies = MvwFrequencyBySchoolClassroomTeacher.by_unity_id(unity_id)
                                                            .by_date_between(start_date, end_date)
    @done_frequencies = @done_frequencies.by_classroom_id(classroom_id) if classroom_id
    @done_frequencies = @done_frequencies.by_teacher_id(teacher_id) if teacher_id
    @done_frequencies = @done_frequencies.group_by(&:frequency_date).size

    ((@done_frequencies * 100).to_f / school_days).round(2)
  end

  def content_record_done_percentage(
    unity_id,
    start_date,
    end_date,
    school_days,
    classroom_id = nil,
    teacher_id = nil
  )
    @done_content_records = MvwContentRecordBySchoolClassroomTeacher.by_unity_id(unity_id)
                                                                    .by_date_between(start_date, end_date)
    @done_content_records = @done_content_records.by_classroom_id(classroom_id) if classroom_id
    @done_content_records = @done_content_records.by_teacher_id(teacher_id) if teacher_id
    @done_content_records = @done_content_records.group_by(&:record_date).size

    ((@done_content_records * 100).to_f / school_days).round(2)
  end

  def percents(classrooms_ids = nil, teacher_id = nil)
    percents = []

    @school_days_by_unity.each do |unity_id, school_days|
      unity = Unity.find(unity_id)

      if classrooms_ids.present?
        classrooms_ids.each do |classroom_id|
          percents << build_percent_table(
            unity,
            school_days[:start_date],
            school_days[:end_date],
            school_days[:school_days],
            classroom_id,
            teacher_id
          )
        end
      else
        percents << build_percent_table(
          unity,
          school_days[:start_date],
          school_days[:end_date],
          school_days[:school_days]
        )
      end
    end

    percents
  end

  def build_percent_table(unity, start_date, end_date, school_days, classroom_id = nil, teacher_id = nil)
    frequency_percentage = frequency_done_percentage(
      unity.id,
      start_date,
      end_date,
      school_days,
      classroom_id,
      teacher_id
    )
    content_record_percentage = content_record_done_percentage(
      unity.id,
      start_date,
      end_date,
      school_days,
      classroom_id,
      teacher_id
    )

    if classroom_id
      classroom = Classroom.find(classroom_id)

      if teacher_id.blank?
        OpenStruct.new(
          unity_id: unity.id,
          unity_name: unity.name,
          classroom_id: classroom.id,
          start_date: start_date,
          end_date: end_date,
          classroom_description: classroom.description,
          frequency_percentage: frequency_percentage,
          content_record_percentage: content_record_percentage
        )
      else
        teacher = Teacher.find(teacher_id)

        OpenStruct.new(
          teacher_id: teacher_id,
          start_date: start_date,
          end_date: end_date,
          teacher_name: teacher.name,
          frequency_percentage: frequency_percentage,
          content_record_percentage: content_record_percentage,
          frequency_days: @done_frequencies,
          content_record_days: @done_content_records
        )
      end
    else
      OpenStruct.new(
        unity_id: unity.id,
        unity_name: unity.name,
        start_date: start_date,
        end_date: end_date,
        frequency_percentage: frequency_percentage,
        content_record_percentage: content_record_percentage
      )
    end
  end

  def filter(percents, params)
    return percents if params.blank?

    params.delete_if do |_filter, value|
      value.blank?
    end

    params.each do |filter, value|
      next if ['frequency_percentage', 'content_record_percentage'].include?(filter)

      percents = percents.select { |school_percent|
        if ['unity_id', 'classroom_id'].include?(filter)
          school_percent.send(filter).to_i == value.to_i
        elsif filter == 'frequency_operator'
          compare(
            school_percent.send(:frequency_percentage).to_f,
            value,
            params[:frequency_percentage].to_f
          )
        else
          compare(
            school_percent.send(:content_record_percentage).to_f,
            value,
            params[:content_record_percentage].to_f
          )
        end
      }
    end

    percents
  end

  def compare(percent, with, value)
    case with
    when ComparativeOperators::EQUALS
      percent == value
    when ComparativeOperators::GREATER_THAN
      percent > value
    when ComparativeOperators::LESS_THAN
      percent < value
    when ComparativeOperators::GREATER_THAN_OR_EQUAL_TO
      percent >= value
    when ComparativeOperators::LESS_THAN_OR_EQUAL_TO
      percent <= value
    end
  end

  def paginate(array)
    Kaminari.paginate_array(array).page(params[:page]).per(10)
  end

  def unknown_teacher_frequency_done(unity_id, start_date, end_date, school_days)
    done_frequencies = DailyFrequency.joins(classroom: :unity)
                                     .by_unity_id(unity_id)
                                     .by_frequency_date_between(start_date, end_date)
                                     .where('EXTRACT(YEAR FROM frequency_date) = ?', current_user_school_year)
                                     .where(owner_teacher_id: nil)
                                     .group_by(&:frequency_date).size

    ((done_frequencies * 100).to_f / school_days).round(2)
  end
end
