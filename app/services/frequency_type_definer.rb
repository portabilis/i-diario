class FrequencyTypeDefiner

  attr_reader :frequency_type

  def initialize(classroom, teacher)
    @classroom = classroom
    @teacher = teacher
  end

  def define!
    if @classroom.exam_rule.frequency_type == FrequencyTypes::BY_DISCIPLINE
      @frequency_type = FrequencyTypes::BY_DISCIPLINE
      return
    end

    specific_area_record = TeacherDisciplineClassroom
        .find_by(teacher_id: @teacher.id,
                 classroom_id: @classroom.id,
                 year: current_year,
                 specific_area: 1,
                 active: true)

    if specific_area_record
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
