class StudentsInRecoveryFetcher
  def initialize(ieducar_api_configuration, classroom_id, discipline_id, school_calendar_step_id, date)
    @ieducar_api_configuration = ieducar_api_configuration
    @classroom_id = classroom_id
    @discipline_id = discipline_id
    @school_calendar_step_id = school_calendar_step_id
    @date = date
  end

  def fetch
    case classroom.exam_rule.recovery_type
    when RecoveryTypes::PARALLEL
      @students = fetch_students_in_parallel_recovery
    when RecoveryTypes::SPECIFIC
      @students = fetch_students_in_specific_recovery
    else
      @students = []
    end

    @students
  end

  private

  def classroom
    Classroom.find(@classroom_id)
  end

  def discipline
    Discipline.find(@discipline_id)
  end

  def school_calendar_step
    SchoolCalendarStep.find(@school_calendar_step_id)
  end

  def fetch_students_in_parallel_recovery
    @students = StudentsFetcher.new(
        @ieducar_api_configuration,
        classroom.api_code,
        discipline.api_code,
        @date
      )
      .fetch

    if classroom.exam_rule.parallel_recovery_average
      @students = @students.select do |student|
        average = student.average(discipline.id, school_calendar_step.id)
        average < classroom.exam_rule.parallel_recovery_average
      end
    end

    @students
  end

  def fetch_students_in_specific_recovery
    @students = []

    school_calendar_steps = RecoverySchoolCalendarStepsFetcher.new(
      @school_calendar_step_id,
      @classroom_id
      )
      .fetch

    recovery_exam_rule = classroom.exam_rule.recovery_exam_rules.find do |recovery_diary_record|
      recovery_diary_record.steps.last.eql?(school_calendar_step.to_number)
    end

    if recovery_exam_rule
      students = StudentsFetcher.new(
          @ieducar_api_configuration,
          classroom.api_code,
          discipline.api_code,
          @date
        )
        .fetch

      @students = students.select do |student|
        sum_averages = 0
        school_calendar_steps.each do |s|
          sum_averages = sum_averages + student.average(@discipline_id, s.id)
        end
        average = sum_averages / school_calendar_steps.count

        average < recovery_exam_rule.average
      end
    end

    @students
  end
end
