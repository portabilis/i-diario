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

    if (classroom.exam_rule.differentiated_exam_rule.blank? ||
        classroom.exam_rule.differentiated_exam_rule.recovery_type == classroom.exam_rule.recovery_type)
      @students += fetch_by_recovery_type(classroom.exam_rule.recovery_type)
    else
      @students += fetch_by_recovery_type(classroom.exam_rule.recovery_type, false)
      @students += fetch_by_recovery_type(classroom.exam_rule.differentiated_exam_rule.recovery_type, true)
    end

    @students.uniq!

    @students
  end

  private

  def fetch_by_recovery_type(recovery_type, differentiated = nil)
    case recovery_type
    when RecoveryTypes::PARALLEL
      students = fetch_students_in_parallel_recovery(differentiated)
    when RecoveryTypes::SPECIFIC
      students = fetch_students_in_specific_recovery(differentiated)
    else
      students = []
    end

    students
  end

  def classroom
    @classroom ||= Classroom.find(@classroom_id)
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

  def enrollment_students
    @enrollment_students ||= begin
      end_at = @date.to_date > step.end_at ? step.end_at : @date.to_date

      StudentEnrollmentsList.new(
        classroom: classroom,
        discipline: discipline,
        start_at: step.start_at,
        end_at: end_at,
        search_type: :by_date_range
      ).student_enrollments.map(&:student)
    end
  end

  def fetch_students_in_parallel_recovery(differentiated = nil)
    students = enrollment_students

    if classroom.exam_rule.parallel_recovery_average
      students = students.select { |student|
        if (average = student.average(classroom, discipline, step))
          average < classroom.exam_rule.parallel_recovery_average
        end
      }
    end

    filter_differentiated_students(students, differentiated)
  end

  def fetch_students_in_specific_recovery(differentiated = nil)
    students = []

    recovery_steps = RecoveryStepsFetcher.new(step, classroom).fetch

    recovery_exam_rule = classroom.exam_rule.recovery_exam_rules.find { |recovery_diary_record|
      recovery_diary_record.steps.last.eql?(@step.to_number)
    }

    if recovery_exam_rule.present?
      students = enrollment_students.select { |student|
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

  def filter_differentiated_students(students, differentiated)
    if differentiated == !!differentiated
      students = students.select do |student|
        student.uses_differentiated_exam_rule == differentiated
      end
    end

    students
  end
end
