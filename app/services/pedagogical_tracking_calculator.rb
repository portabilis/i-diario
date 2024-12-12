# app/services/pedagogical_tracking_calculator.rb
class PedagogicalTrackingCalculator
  def initialize(entity:, year:, current_user:, params:, employee_unities: nil)
    @entity = entity
    @year = year
    @current_user = current_user
    @params = params
    @employee_unities = employee_unities
  end

  def calculate_index_data
    unity_id = extract_unity_id
    start_date, end_date = extract_date_range

    fetch_school_days_by_unity(unity_id, start_date, end_date)

    # Pré-carregar os dados de frequências, conteúdos e frequências com professor desconhecido
    preload_frequencies_and_contents(start_date, end_date, unity_id ? [unity_id] : nil)

    school_days = @school_days_by_unity.values
                                       .max_by { |data| data[:school_days] }[:school_days]

    percentages = calculate_all_percentages
    percents = fetch_percents(unity_id, start_date, end_date)

    {
      updated_at: updated_at_data,
      school_days: school_days,
      school_frequency_done_percentage: percentages[:frequency_done_percentage],
      school_content_record_done_percentage: percentages[:content_record_percentage],
      unknown_teachers: percentages[:unknown_teacher_percentage],
      unity_id: unity_id,
      percents: percents,
      start_date: start_date,
      end_date: end_date
    }
  end

  def calculate_teachers_data(unity_id:, classroom_id:, teacher_id:, start_date:, end_date:, filter_params:)
    fetch_school_days_by_unity(unity_id, start_date, end_date)
    preload_frequencies_and_contents(start_date, end_date, [unity_id].compact)

    teachers_ids = teachers_for(classroom_id, teacher_id)
    teacher_percents = calculate_teacher_percents(classroom_id, teachers_ids, filter_params)

    teacher_percents
  end

  private

  def extract_unity_id
    employee_unity = @employee_unities.first.id if @employee_unities.presence&.one?
    @params.dig(:search, :unity_id).presence || @params[:unity_id] || employee_unity
  end

  def extract_date_range
    start_date = (@params.dig(:search, :start_date).presence || @params[:start_date]).try(:to_date)
    end_date = (@params.dig(:search, :end_date).presence || @params[:end_date]).try(:to_date)
    [start_date, end_date]
  end

  def updated_at_data
    last_refresh = MvwFrequencyBySchoolClassroomTeacher.first&.last_refresh ||
                   MvwContentRecordBySchoolClassroomTeacher.first&.last_refresh

    return unless last_refresh

    {
      date: last_refresh.to_date.strftime('%d/%m/%Y'),
      hour: last_refresh.hour
    }
  end

  def fetch_school_days_by_unity(unity_id, start_date, end_date)
    unity = Unity.find(unity_id) if unity_id
    unities = unity || @employee_unities || all_unities

    now = Time.current
    midnight = now.end_of_day
    expires_in = (midnight - now).to_i

    @school_days_by_unity =
      SchoolDaysCounterService.new(
        unities: unities,
        all_unities_size: all_unities.size,
        start_date: start_date,
        end_date: end_date,
        year: @year
      ).school_days
  end

  def all_unities
    @all_unities ||= Unity.joins(:school_calendars)
                          .where(school_calendars: { year: @year })
                          .ordered
  end

  def unities_total
    @unities_total ||= @school_days_by_unity.size
  end

  def preload_frequencies_and_contents(start_date, end_date, specific_unities = nil)
    unity_ids = specific_unities || @school_days_by_unity.keys

    @frequencies_by_unity = load_frequencies_by_unity(unity_ids, start_date, end_date)
    @contents_by_unity = load_contents_by_unity(unity_ids, start_date, end_date)
    @unknown_frequencies_by_unity = load_unknown_frequencies_by_unity(unity_ids, start_date, end_date)
  end

  def load_frequencies_by_unity(unity_ids, start_date, end_date)
    records = MvwFrequencyBySchoolClassroomTeacher
                .by_unity_id(unity_ids)
                .by_date_between(start_date, end_date)
                .distinct
                .pluck(:unity_id, :classroom_id, :teacher_id, :frequency_date)
  
    frequencies_hash = Hash.new { |h, k| h[k] = [] }
  
    records.each do |u_id, c_id, t_id, f_date|
      frequencies_hash[u_id] << [c_id, t_id, f_date]
    end
  
    frequencies_hash
  end
  
  def load_contents_by_unity(unity_ids, start_date, end_date)
    records = MvwContentRecordBySchoolClassroomTeacher
                .by_unity_id(unity_ids)
                .by_date_between(start_date, end_date)
                .distinct
                .pluck(:unity_id, :classroom_id, :teacher_id, :record_date)
  
    contents_hash = Hash.new { |h, k| h[k] = [] }
  
    records.each do |u_id, c_id, t_id, r_date|
      contents_hash[u_id] << [c_id, t_id, r_date]
    end
  
    contents_hash
  end
  
  def load_unknown_frequencies_by_unity(unity_ids, start_date, end_date)
    records = DailyFrequency
                .joins(classroom: :unity)
                .where(unities: { id: unity_ids })
                .where('EXTRACT(YEAR FROM frequency_date) = ?', @year)
                .where(owner_teacher_id: nil)
                .where(frequency_date: start_date..end_date)
                .distinct
                .pluck('unities.id', 'classrooms.id', 'NULL', 'daily_frequencies.frequency_date')
  
    unknown_hash = Hash.new { |h, k| h[k] = [] }
  
    records.each do |u_id, c_id, _null_t_id, f_date|
      unknown_hash[u_id] << [c_id, nil, f_date]
    end
  
    unknown_hash
  end
 
  def calculate_all_percentages
    total_frequencies = 0
    total_unknown_teachers = 0
    total_content_records = 0

    @school_days_by_unity.each do |unity_id, data|
      start_date = data[:start_date]
      end_date = data[:end_date]
      total_days = data[:school_days]

      total_frequencies += frequency_done_percentage(unity_id, start_date, end_date, total_days)
      total_unknown_teachers += unknown_teacher_frequency_done(unity_id, start_date, end_date, total_days)
      total_content_records += content_record_done_percentage(unity_id, start_date, end_date, total_days)
    end

    return {
      frequency_done_percentage: 0,
      unknown_teacher_percentage: 0,
      content_record_percentage: 0
    } if unities_total.zero?

    {
      frequency_done_percentage: (total_frequencies.to_f / unities_total).round(2),
      unknown_teacher_percentage: (total_unknown_teachers.to_f / unities_total).round(2),
      content_record_percentage: (total_content_records.to_f / unities_total).round(2)
    }
  end

  def frequency_done_percentage(unity_id, start_date, end_date, school_days, classroom_id = nil, teacher_id = nil)
    records = @frequencies_by_unity[unity_id] || []
  
    records = records.select { |c_id, t_id, date|
      (classroom_id.nil? || c_id == classroom_id.to_i) &&
      (teacher_id.nil? || t_id == teacher_id.to_i) &&
      date >= start_date && date <= end_date
    }
  
    distinct_days = records.map(&:last).uniq.size
  
    ((distinct_days * 100).to_f / school_days).round(2)
  end
  
  def content_record_done_percentage(unity_id, start_date, end_date, school_days, classroom_id = nil, teacher_id = nil)
    records = @contents_by_unity[unity_id] || []
  
    records = records.select { |c_id, t_id, date|
      (classroom_id.nil? || c_id == classroom_id.to_i) &&
      (teacher_id.nil? || t_id == teacher_id.to_i) &&
      date >= start_date && date <= end_date
    }
  
    distinct_days = records.map(&:last).uniq.size
    ((distinct_days * 100).to_f / school_days).round(2)
  end
  
  def unknown_teacher_frequency_done(unity_id, start_date, end_date, school_days)
    records = @unknown_frequencies_by_unity[unity_id] || []
  
    records = records.select { |c_id, t_id, date|
      date >= start_date && date <= end_date
    }
  
    distinct_days = records.map(&:last).uniq.size
    ((distinct_days * 100).to_f / school_days).round(2)
  end

  def fetch_percents(unity_id, start_date, end_date)
    if unity_id
      classrooms = Classroom.where(unity_id: unity_id, year: @year).ordered
      paginate(filter_from_params(percents(classrooms.pluck(:id)), @params.dig(:filter)))
    else
      paginate(filter_from_params(percents, @params.dig(:filter)))
    end
  end

  def percents(classrooms_ids = nil, teacher_id = nil)
    unity_ids = @school_days_by_unity.keys
    unities = Unity.where(id: unity_ids).index_by(&:id)

    result = []
    @school_days_by_unity.each do |unity_id, data|
      unity = unities[unity_id]

      if classrooms_ids.present?
        classrooms_ids.each do |classroom_id|
          result << build_percent_table(
            unity,
            data[:start_date],
            data[:end_date],
            data[:school_days],
            classroom_id,
            teacher_id
          )
        end
      else
        result << build_percent_table(
          unity,
          data[:start_date],
          data[:end_date],
          data[:school_days]
        )
      end
    end

    result
  end

  def build_percent_table(unity, start_date, end_date, school_days, classroom_id = nil, teacher_id = nil)
    frequency_percentage = frequency_done_percentage(unity.id, start_date, end_date, school_days, classroom_id, teacher_id)
    content_record_percentage = content_record_done_percentage(unity.id, start_date, end_date, school_days, classroom_id, teacher_id)

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
          content_record_percentage: content_record_percentage
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

  def filter_from_params(percents, params)
    return percents if params.blank?

    params.delete_if { |_filter, value| value.blank? }

    params.each do |filter, value|
      next if ['frequency_percentage', 'content_record_percentage'].include?(filter)

      percents = percents.select do |school_percent|
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
      end
    end

    percents
  end

  def compare(percent, operator, value)
    case operator
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
    Kaminari.paginate_array(array).page(@params[:page]).per(10)
  end

  def teachers_for(classroom_id, teacher_id)
    [teacher_id].compact.presence ||
      Teacher.by_classroom(classroom_id)
             .by_year(@year)
             .pluck(:id).uniq
  end

  def calculate_teacher_percents(classroom_id, teachers_ids, filter_params)
    teacher_percents = []
    teachers_ids.each do |tid|
      teacher_percents << percents([classroom_id], tid)
    end

    teacher_percents = teacher_percents.flatten
    filter_from_params(teacher_percents, filter_params)
  end
end