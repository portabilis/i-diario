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
    return if teacher_id.blank? || unity.blank?

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
    return [] if unity.nil?

    Classroom.by_unity_and_teacher(unity.id, teacher_id).by_year(current_school_year).ordered.distinct
  end

  def disciplines_fetch
    return [] if @classrooms.nil?

    Discipline.includes(:knowledge_area).by_teacher_and_classroom(teacher_id, @classrooms.map(&:id)).ordered.distinct
  end

  def classroom_grades
    return [] if @disciplines.nil? || @classrooms.nil? || teacher_id.nil?

    ClassroomsGrade.includes(:grade).where(classroom_id: @classrooms.map(&:id)).distinct
  end

  protected

  attr_accessor :teacher_id, :unity, :current_school_year
end
