class AttendanceRecordReportByStudentForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :period,
                :start_at,
                :end_at,
                :school_calendar_year,
                :school_calendar,
                :current_user_id

  validates :start_at, presence: true, date: true, timeliness: {
    on_or_before: :end_at, type: :date, on_or_before_message: I18n.t('errors.messages.on_or_before_message')
  }
  validates :end_at, presence: true, date: true, timeliness: {
    on_or_after: :start_at, type: :date, on_or_after_message: I18n.t('errors.messages.on_or_after_message')
  }
  validates :unity_id, presence: true
  validates :classroom_id, presence: true
  validates :period, presence: true
  validates :school_calendar_year, presence: true
  validates :current_user_id, presence: true
  validates :school_calendar, presence: true

  def unity
    unity = Unity.find(unity_id) if unity_id.present?
  end

  def current_user
    user = User.find(current_user_id) if current_user_id.present?
  end

  def select_all_classrooms
    return Classroom.where(id: classroom_id) unless classroom_id.eql?('all')
    return Classroom.by_unity(unity_id).distinct.includes(:grades).order(:id) unless current_user.teacher?

    Classroom.by_unity_and_teacher(unity_id, current_user.teacher_id)
             .includes(:grades)
             .distinct
             .order(:id)
  end

  def enrollment_classrooms_list
    classrooms = select_all_classrooms

    enrollment_classrooms = StudentEnrollmentClassroom
      .includes(student_enrollment: :student)
      .includes(classrooms_grade: :classroom)
      .by_classroom(classroom_id.eql?('all') ? classrooms.map(&:id) : classroom_id)
      .by_date_range(start_at, end_at)
      .by_period(adjusted_period)
      .where(classrooms_grade: { classrooms: { year: school_calendar_year } })
      .distinct
      .order('classrooms_grades.classroom_id')
      .order('sequence ASC, students.name ASC')

    info_students(enrollment_classrooms)
  end

  def info_students(enrollment_classrooms)
    enrollment_classrooms.map do |student_enrollment_classroom|
      student = student_enrollment_classroom.student_enrollment.student
      sequence = student_enrollment_classroom.sequence if @show_inactive_enrollments
      classroom_id = student_enrollment_classroom.classrooms_grade.classroom_id

      {
        student_id: student.id,
        student_name: student.name,
        sequence: sequence,
        classroom_id: classroom_id
      }
    end
  end

  def students_by_classrooms
    select_all_classrooms.map do |classroom|
      students = enrollment_classrooms_list.select{ |student| student[:classroom_id].eql?(classroom.id) }

      next if students.empty?

      {
        classroom.id => {
          classroom_name: classroom.description,
          grade_name: classroom.grades.first.description,
          students: students.map do |student|
            {
              student_id: student[:student_id],
              student_name: student[:student_name],
              sequence: student[:sequence]
              # frequency: student[:frequency]
            }
          end
        }
      }
    end.compact.reduce(&:merge)
  end

  def fetch_daily_frequencies(student_id, classroom_id)
    #  todas as frequencias do periodo e da turma selecionada
    daily_frequencies = DailyFrequencyQuery.call(
      classroom_id: classroom_id,
      period: adjusted_period,
      frequency_date: start_at..end_at,
      all_students_frequencies: true
    ).order(:classroom_id)

    # método para converter a frequencias em geral
    frequencies = convert_frequency_in_global(daily_frequencies)

    # array de todas frequencias tratadas
    todas_as_frequencias = frequencies + daily_frequencies

    # método para verificar total de aulas dadas e total de faltas aluno
    totais = totais(todas_as_frequencias.map(&:students))

    # calcular porcentagem frequencia do aluno
    multiplicacao = faltas_do_aluno * 100
    resultado = 100 - (multiplicacao / count_dias_frequencia).to_s + '%'


    { student: student_id, frequency: (((total.to_f - faltas.to_f) * 100) / total.to_f).to_f.round(2) }
  end

  def adjusted_period
    return Periods::FULL if period.eql?('all') || period.eql?(Periods::FULL)

    period
  end

  def convert_frequency_in_global(daily_frequencies)
    return if daily_frequencies.map(&:discipline_id).uniq.compact.empty?

    frequencies_by_discipline = daily_frequencies
      .where.not(discipline_id: nil, class_number: nil)
  end



  def students_frequencies_percentage
    percentage_by_student = Hash.new(0)
    daily_frequency_by_student = Hash.new { |hash, key| hash[key] = Set.new }

    percentage_by_student = fetch_daily_frequencies.flat_map do |daily_frequency|
      frequency_date = daily_frequency.frequency_date
      classroom_id = daily_frequency.classroom_id

      {
        classroom_id => {
          students: daily_frequency.students.map do |daily_frequency_student|
            student_id = daily_frequency_student.student_id

            next if daily_frequency_by_student[student_id].include?(frequency_date)

            infrequency_count = daily_frequency_student.present? ? 0 : 1
            infrequency_count += 1 if daily_frequency_student.present?

            {
              student_id: student_id,
              infrequency: infrequency_count
            }.tap do
              daily_frequency_by_student[student_id].add(frequency_date)
            end
          end.compact
        }
      }
    end.compact

    total_school_days = UnitySchoolDay.by_unity_id(unity_id)
                                      .by_year(school_calendar_year)
                                      .by_date_between(start_at, end_at)
                                      .count

    percentage_by_student.each do |key, values|
      next if key.eql?('classroom_id')
      multiplication = (total_school_days - values) * 100
      result = multiplication / total_school_days
      percentage_by_student[key] = result.negative? ? 0.to_s + '%' : result.to_s + '%'
    end

    percentage_by_student
  end

  def show_inactive_enrollments
    @show_inactive_enrollments ||= GeneralConfiguration.first.show_inactive_enrollments
  end
end
