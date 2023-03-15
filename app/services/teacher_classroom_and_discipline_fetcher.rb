class TeacherClassroomAndDisciplineFetcher
  def initialize(teacher_id, unity, current_school_year)
    self.teacher_id = teacher_id
    self.unity = unity
    self.current_school_year = current_school_year
  end

  def self.fetch!(teacher_id, unity, current_school_year)
    new(teacher_id, unity, current_school_year).fetch!
  end

  def fetch!
    return unless teacher_id || unity

    fetch_linked_by_teacher = {}

    @classrooms ||= classrooms_fetch
    @disciplines ||= disciplines_fetch
    @classroom_grades ||= classroom_grades

    fetch_linked_by_teacher[:classrooms] = @classrooms
    fetch_linked_by_teacher[:disciplines] = @disciplines
    fetch_linked_by_teacher[:classroom_grades] = @classroom_grades

    fetch_linked_by_teacher
  end

  def classrooms_fetch
    return {} if unity.nil?

    Classroom.by_unity_and_teacher(unity.id, teacher_id).by_year(current_school_year).ordered.uniq
  end

  def disciplines_fetch
    return {} if @classrooms.nil?

    Discipline.by_teacher_and_classroom(teacher_id, @classrooms.map(&:id)).ordered.uniq
  end

  def classroom_grades
    return {} if @disciplines.nil? || @classrooms.nil? || teacher_id.nil?

    classroom_grades = {}

    @query_classroom_grades ||= ClassroomsGrade.where(classroom_id: @classrooms.map(&:id))

    classroom_grades[:id] = @query_classroom_grades.map(&:id)
    classroom_grades[:grade_id] = @query_classroom_grades.map(&:grade_id)
    classroom_grades[:exam_rule_id] = @query_classroom_grades.map(&:exam_rule_id)

    classroom_grades
  end

  protected

  attr_accessor :teacher_id, :unity, :current_school_year
end
