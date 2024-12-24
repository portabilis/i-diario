class FrequencyTypeDefiner
  attr_reader :frequency_type

  def self.allow_frequency_by_discipline?(classroom, teacher_id, exam_rule = nil)
    new(classroom, teacher_id, exam_rule).allow_frequency_by_discipline?
  end

  def initialize(classroom, teacher_id, exam_rule = nil, year: nil)
    @classroom = classroom
    @teacher_id = teacher_id
    @exam_rule = exam_rule || classroom.classrooms_grades.first.try(:exam_rule)
    @year = year
  end

  def allow_frequency_by_discipline?
    define!

    @frequency_type == FrequencyTypes::BY_DISCIPLINE
  end

  def define!
    return if @exam_rule.blank? || @teacher_id.blank? || @classroom.blank?

    @frequency_type = @exam_rule.frequency_type

    return if @exam_rule.frequency_type == FrequencyTypes::BY_DISCIPLINE

    define_frequency_type
  end

  private

  def define_frequency_type
    grade_ids = @classroom.classrooms_grades.pluck(:grade_id)

    allow_absence_by_discipline_record = TeacherDisciplineClassroom.find_by(
      teacher_id: @teacher_id,
      classroom_id: @classroom.id,
      year: current_year,
      allow_absence_by_discipline: 1,
      grade_id: grade_ids,
      active: true
    )

    @frequency_type = allow_absence_by_discipline_record ? FrequencyTypes::BY_DISCIPLINE : FrequencyTypes::GENERAL
  end

  def current_year
    @year || CurrentSchoolYearFetcher.new(unity, @classroom).fetch
  end

  def unity
    Unity.find(@classroom.unity_id)
  end
end
