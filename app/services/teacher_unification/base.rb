class TeacherUnification
  class Base
    KEEP_ASSOCIATIONS = [
      :audits,
      :teacher_unifications,
      :teacher_unification_teachers
    ].freeze

    def initialize(main_teacher, secondary_teachers)
      @main_teacher = main_teacher
      @secondary_teachers = secondary_teachers
    end
  end
end
