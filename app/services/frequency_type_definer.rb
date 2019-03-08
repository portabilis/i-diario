class FrequencyTypeDefiner
  attr_reader :frequency_type

  def initialize(classroom, teacher, exam_rule = nil, year: nil)
    @classroom = classroom
    @teacher = teacher
    @exam_rule = exam_rule || classroom.try(:exam_rule)
    @year = year
  end

  def define!
    return if @exam_rule.blank?

    @frequency_type = @exam_rule.frequency_type

    return if @exam_rule.frequency_type == FrequencyTypes::BY_DISCIPLINE || @teacher.blank? || @classroom.blank?

    define_frequency_type
  end

  def allow_frequency_by_discipline?
    define!

    @frequency_type == FrequencyTypes::BY_DISCIPLINE
  end

  def self.allow_frequency_by_discipline?(classroom, teacher, exam_rule = nil)
    new(classroom, teacher, exam_rule).allow_frequency_by_discipline?
  end

  private

  def define_frequency_type
    allow_absence_by_discipline_record = TeacherDisciplineClassroom.find_by(
      teacher_id: @teacher.id,
      classroom_id: @classroom.id,
      year: current_year,
      allow_absence_by_discipline: 1,
      active: true
    )

    @frequency_type = allow_absence_by_discipline_record ? FrequencyTypes::BY_DISCIPLINE : FrequencyTypes::GENERAL
  end

  def current_year
    @year || CurrentSchoolYearFetcher.new(unity).fetch
  end

  def unity
    Unity.find(@classroom.unity_id)
  end
end
