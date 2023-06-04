class UnitiesClassroomsDisciplinesByTeacher
  def initialize(teacher_id, unity_id, classroom_id, discipline_id = nil)
    self.teacher_id = teacher_id
    self.unity_id = unity_id
    self.classroom_id = classroom_id
    self.discipline_id = discipline_id
  end

  def fetch!
    return unless teacher_id

    self.unities = Unity.by_teacher(teacher_id)
                        .ordered
                        .distinct

    if unity_id
      self.classrooms = Classroom.by_unity_and_teacher(unity_id, teacher_id)
                                 .ordered
                                 .distinct
    else
      self.classrooms = {}
    end

    if classroom_id
      @disciplines = Discipline.by_teacher_and_classroom(teacher_id, classroom_id)
                               .ordered
                               .distinct
    else
      @disciplines = {}
    end

    if discipline_id
      @avaliations = Avaliation.teacher_avaliations(teacher_id, classroom_id, discipline_id)
                               .ordered
                               .distinct
    else
      @avaliations = {}
    end
    true
  end

  attr_reader :unities, :classrooms, :disciplines, :avaliations

  protected

  attr_accessor :teacher_id, :unity_id, :classroom_id, :discipline_id
  attr_writer :unities, :classrooms, :disciplines, :avaliations
end
