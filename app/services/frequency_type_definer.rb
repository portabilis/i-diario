class FrequencyTypeDefiner

  attr_reader :frequency_type

  def initialize(classroom, teacher, exam_rule = nil)
    @classroom = classroom
    @teacher = teacher
    @exam_rule = exam_rule || classroom.try(:exam_rule)
  end

  def define!
    if !@classroom
      return
    end

    if !@teacher
      @frequency_type = @exam_rule.frequency_type
      return
    end

    if @exam_rule.frequency_type == FrequencyTypes::BY_DISCIPLINE
      @frequency_type = FrequencyTypes::BY_DISCIPLINE
      return
    end

    allow_absence_by_discipline_record = TeacherDisciplineClassroom
        .find_by(teacher_id: @teacher.id,
                 classroom_id: @classroom.id,
                 year: current_year,
                 allow_absence_by_discipline: 1,
                 active: true)

    if allow_absence_by_discipline_record
      @frequency_type = FrequencyTypes::BY_DISCIPLINE
    else
      @frequency_type = FrequencyTypes::GENERAL
    end

  end

  def current_year
    CurrentSchoolYearFetcher.new(unity).fetch
  end

  def unity
    Unity.find(@classroom.unity_id)
  end
end
