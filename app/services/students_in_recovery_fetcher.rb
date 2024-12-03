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

    filter_differentiated_students(students, differentiated)
  end

  def filter_students_in_recovery
    classroom_grade_ids = classroom_grades_with_recovery_rule.map(&:id)
    fetch_student_enrollment_classroooms(classroom_grade_ids)
  end

  def fetch_students_in_specific_recovery(differentiated = nil)
    students = []

    recovery_steps = RecoveryStepsFetcher.new(step, classroom).fetch
    recovery_exam_rule = exam_rule.recovery_exam_rules.find { |recovery_diary_record|
      recovery_diary_record.steps.last.eql?(@step.to_number)
    }

    if recovery_exam_rule.present?
      students = filter_students_in_recovery.select do |student|
        sum_averages = recovery_steps.sum do |step|
          student[:student].average(classroom, discipline, step) || 0
        end
        average = sum_averages / recovery_steps.count.to_f

        average < recovery_exam_rule.average
      end
    end

    filter_differentiated_students(students, differentiated)
  end

  def filter_differentiated_students(students, differentiated)
    if differentiated == !!differentiated
      students = students.select do |student|
        student = student[:student] if student[:student].present?
        student.uses_differentiated_exam_rule == differentiated
      end
    end

    students
  end

  def fetch_student_enrollment_classroooms(classroom_grade_ids)
    @student_enrollment_classroooms ||= StudentEnrollmentClassroomsRetriever.call(
      classrooms: classroom,
      disciplines: discipline,
      date: @date,
      classroom_grades: classroom_grade_ids,
      search_type: :by_date
    )
  end

  def classroom_grades_with_recovery_rule
    return @classroom_grade if @classroom_grade.present?

    @classroom_grade = []

    classroom_grades&.each do |classroom_grade|
      @classroom_grade << classroom_grade unless classroom_grade.exam_rule.recovery_type.eql?(0)
    end

    @classroom_grade = classroom_grades if @classroom_grade.empty?
    @classroom_grade
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

  def exam_rule
    @exam_rule ||= classroom_grades_with_recovery_rule.first.exam_rule
  end

  def classroom
    @classroom ||= Classroom.find(@classroom_id)
  end
end
