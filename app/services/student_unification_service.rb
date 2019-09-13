class StudentUnificationService
  KEEP_ASSOCIATIONS = [
    :audits,
    :deficiencies,
    :student_enrollments,
    :student_unifications,
    :student_unification_students
  ].freeze

  ASSOCIATIONS_TYPES = [
    :has_many,
    :has_and_belongs_to_many
  ].freeze

  def initialize(main_student, secondary_students)
    @main_student = main_student
    @secondary_students = secondary_students
  end

  def run!
    @secondary_students.each do |secondary_student|
      ASSOCIATIONS_TYPES.each do |association_type|
        Student.reflect_on_all_associations(association_type).each do |association|
          next if KEEP_ASSOCIATIONS.include?(association.name)

          secondary_student.send(association.name).each do |record|
            begin
              unify(record, association_type)
            rescue ActiveRecord::RecordNotUnique
            rescue ActiveRecord::StatementInvalid => exception
              db_check_messages = ['check_conceptual_exam_is_unique', 'check_descriptive_exam_is_unique']

              raise exception unless db_check_messages.any? { |check_message|
                exception.message.include?(check_message)
              }
            end
          end
        end
      end
    end
  end

  def unify(record, association_type)
    case association_type
    when :has_many
      unify_has_many(record)
    when :has_and_belongs_to_many
      unify_has_and_belongs_to_many(record)
    end

    record.save!(validate: false)
  end

  def unify_has_many(record)
    record.student_id = @main_student.id
  end

  def unify_has_and_belongs_to_many(record)
    record.students.delete_if do |student|
      student.id != @main_student.id
    end

    record.students << Student.with_discarded.find(@main_student.id)
  end
end
