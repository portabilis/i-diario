# OPTIMIZE: Performance na pagina diario-de-recuperacoes-de-etapas/novo
# A pagina diario-de-recuperacoes-de-etapas/novo demora para carregar por
# conta desse service, toda a filtragem é feita via cadeia de transformação,
# trazendo os dados para a memoria e tratando aqui. Para diminuir o tempo de
# carregamento e o custi de infra, o ideal seria refatorar essa classe e delegar
# mais filtros ao postgres antes de transformar os dados em memoria
class StudentsInRecoveryFetcher
  def initialize(ieducar_api_configuration, classroom_id, discipline_id, step_id, date)
    @ieducar_api_configuration = ieducar_api_configuration
    @classroom_id = classroom_id
    @discipline_id = discipline_id
    @step_id = step_id
    @date = date
  end

  def fetch
    @students = []

    recovery_type = exam_rule.recovery_type

    if (exam_rule.differentiated_exam_rule.blank? || exam_rule.differentiated_exam_rule.recovery_type == recovery_type)
      @students += fetch_by_recovery_type(recovery_type)
    else
      @students += fetch_by_recovery_type(recovery_type, false)
      @students += fetch_by_recovery_type(exam_rule.differentiated_exam_rule.recovery_type, true)
    end

    @students.uniq!

    @students
  end

  private

  def fetch_by_recovery_type(recovery_type, differentiated = nil)
    return fetch_students_in_parallel_recovery(differentiated) if recovery_type.eql?(RecoveryTypes::PARALLEL)
    return fetch_students_in_specific_recovery(differentiated) if recovery_type.eql?(RecoveryTypes::SPECIFIC)

    []
  end

  def fetch_students_in_parallel_recovery(differentiated = nil)
    students = filter_students_in_recovery

    if exam_rule.parallel_recovery_average
      students = students.select do |student|
        average = student[:student].average(classroom, discipline, step) || 0
        average < exam_rule.parallel_recovery_average
      end
    end

  def classroom
    @classroom ||= Classroom.find(@classroom_id)
  end

  def classroom_grades_with_recovery_rule
    return @classroom_grade if @classroom_grade.present?

    @classroom_grade = []

    recovery_steps = RecoveryStepsFetcher.new(step, classroom).fetch
    recovery_exam_rule = exam_rule.recovery_exam_rules.find { |recovery_diary_record|
      recovery_diary_record.steps.last.eql?(@step.to_number)
    }

    if @classroom_grade.empty?
      classroom_grades
    else
      @classroom_grade
    end
  end

  def classroom_grades
    classroom.classrooms_grades.includes(:exam_rule)
  end

  def discipline
    @discipline ||= Discipline.find(@discipline_id)
  end

  def steps_fetcher
    @steps_fetcher ||= StepsFetcher.new(classroom)
  end

  def step
    @step ||= steps_fetcher.step_by_id(@step_id)
  end

  def student_enrollments(classroom_grade_ids)
    end_at = @date.to_date > step.end_at ? step.end_at : @date.to_date

    @student_enrollments ||= fetch_student_enrollment_classroooms(classroom_grade_ids, discipline, classroom)
  end

  def fetch_student_enrollment_classroooms(classroom_grade_ids, discipline, classroom)
    StudentEnrollmentClassroomsRetriever.call(
      classrooms: classroom,
      disciplines: discipline,
      date: @date,
      classroom_grades: classroom_grade_ids,
      search_type: :by_date
    )
  end

  def fetch_students_in_parallel_recovery(differentiated = nil)
    students = filter_students_in_recovery

    if classroom_grades_with_recovery_rule.first.exam_rule.parallel_recovery_average
      students = students.select do |student|
        average = student[:student].average(classroom, discipline, step) || 0
        average < classroom_grades_with_recovery_rule.first.exam_rule.parallel_recovery_average
      end
    end

    filter_differentiated_students(students, differentiated)
  end

  def filter_students_in_recovery
    classroom_grade_ids = classroom_grades_with_recovery_rule.map(&:id)
    student_enrollments(classroom_grade_ids)
  end

  def fetch_students_in_specific_recovery(differentiated = nil)
    students = []

    recovery_steps = RecoveryStepsFetcher.new(step, classroom).fetch

    recovery_exam_rule = classroom_grades_with_recovery_rule.first.exam_rule.recovery_exam_rules.find { |recovery_diary_record|
      recovery_diary_record.steps.last.eql?(@step.to_number)
    }

    if recovery_exam_rule.present?
      students = filter_students_in_recovery.select { |student|
        sum_averages = 0

        recovery_steps.each do |step|
          next unless (average = student.average(classroom, discipline, step))

          sum_averages += average
        end

        average = sum_averages / recovery_steps.count

        average < recovery_exam_rule.average
      }
    end

    filter_differentiated_students(students, differentiated)
  end

  def exam_rule
    @exam_rule ||= classroom_grades_with_recovery_rule.first.exam_rule
  end

    students
  end
end
