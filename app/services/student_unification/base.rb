class StudentUnification
  class Base
    KEEP_ASSOCIATIONS = [
      :audits,
      :deficiencies,
      :student_enrollments,
      :absence_justifications,
      :student_unifications,
      :student_unification_students
    ].freeze

    def initialize(main_student, secondary_students)
      @main_student = main_student
      @secondary_students = secondary_students
    end

    def keep_associations
      KEEP_ASSOCIATIONS
    end
  end
end
