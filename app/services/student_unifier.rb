class StudentUnifier
  KEEP_ASSOCIATIONS = [:audits, :associated_audits, :student_unifications, :student_unification_students].freeze

  def initialize(main_student, secondary_students)
    @main_student = main_student
    @secondary_students = secondary_students
  end

  def unify!
    @secondary_students.each do |secondary_student|
      Student.reflect_on_all_associations(:has_many).each do |association|
        next if KEEP_ASSOCIATIONS.include?(association.name)

        primary_key = :id
        foreign_key = :student_id

        secondary_student.send(association.name).each do |obj|
          begin
            obj.send("#{foreign_key}=", @main_student.send(primary_key))
            obj.save!(validate: false)
          rescue ActiveRecord::RecordNotUnique
          end
        end
      end
    end
  end
end
