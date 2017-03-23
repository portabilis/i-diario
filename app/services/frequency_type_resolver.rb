class FrequencyTypeResolver
  def initialize(classroom, teacher)
    raise ArgumentError unless classroom && teacher

    @classroom = classroom
    @teacher = teacher
  end

  def resolve
    if @classroom.exam_rule.frequency_type == FrequencyTypes::BY_DISCIPLINE
      return FrequencyTypes::BY_DISCIPLINE
    end

    teacher_discipline_classroom = TeacherDisciplineClassroom.find_by(
      teacher_id: @teacher.id,
      classroom_id: @classroom.id,
      year: current_year,
      allow_absence_by_discipline: 1,
      active: true
    )

    if teacher_discipline_classroom
      FrequencyTypes::BY_DISCIPLINE
    else
      FrequencyTypes::GENERAL
    end
  end

  def general?
    resolve == FrequencyTypes::GENERAL
  end

  def by_discipline?
    resolve == FrequencyTypes::BY_DISCIPLINE
  end

  private

  attr_reader :classroom, :teacher

  def current_year
    CurrentSchoolYearFetcher.new(@classroom.unity).fetch
  end
end
