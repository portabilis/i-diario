class StudentUnificationReverterService
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

          @main_student.send(association.name).each do |record|
            next unless unified?(record, secondary_student.id)

            begin
              revert(record, association_type, secondary_student.id)
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

  def unified?(record, secondary_student_id)
    audits = record.audits
                   .where(action: 'update')
                   .where("audited_changes ILIKE '%student_id:%'")

    return if audits.empty?

    audits.any? { |audit| audit.audited_changes['student_id'] == [secondary_student_id, @main_student.id] }
  end

  def revert(record, association_type, secondary_student_id)
    case association_type
    when :has_many
      revert_unify_has_many(record, secondary_student_id)
    when :has_and_belongs_to_many
      revert_unify_has_and_belongs_to_many(record, secondary_student_id)
    end

    record.save!(validate: false)
  end

  def revert_unify_has_many(record, secondary_student_id)
    record.student_id = secondary_student_id
  end

  def revert_unify_has_and_belongs_to_many(record, secondary_student_id)
    record.students.delete_if do |student|
      student.id != secondary_student_id
    end

    record.students << Student.with_discarded.find(secondary_student_id)
  end
end
