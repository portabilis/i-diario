class StudentUnificationReverterService
  KEEP_ASSOCIATIONS = [
    :audits,
    :deficiencies,
    :student_enrollments,
    :student_unifications,
    :student_unification_students
  ].freeze

  def initialize(main_student, secondary_students)
    @main_student = main_student
    @secondary_students = secondary_students
  end

  def run!
    @secondary_students.each do |secondary_student|
      Student.reflect_on_all_associations(:has_many).each do |association|
        next if KEEP_ASSOCIATIONS.include?(association.name)

        @main_student.send(association.name).each do |record|
          next unless unified?(association.class_name, record.id, secondary_student.id)

          begin
            record.student_id = secondary_student.id
            record.save!(validate: false)
          rescue ActiveRecord::RecordNotUnique
          end
        end
      end
    end
  end

  def unified?(class_name, id, secondary_student_id)
    Audited::Adapters::ActiveRecord::Audit.where(
      auditable_type: class_name,
      auditable_id: id,
      action: 'update'
    ).where(
      "audited_changes ILIKE '%student_id:%#{secondary_student_id}%#{@main_student.id}%'"
    ).exists?
  end
end
