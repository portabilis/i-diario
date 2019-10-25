class StudentUnificationReverterService
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

  def run!
    @secondary_students.each do |secondary_student|
      Student.reflect_on_all_associations(:has_many).each do |association|
        next if KEEP_ASSOCIATIONS.include?(association.name)

        association.klass.with_discarded.where(student_id: @main_student.id).each do |record|
          next unless unified?(record, secondary_student.id)

          begin
            record.student_id = secondary_student.id
            record.discarded_at = nil if record.discarded?
            record.save!(validate: false)
          rescue ActiveRecord::RecordNotUnique
          rescue ActiveRecord::StatementInvalid => exception
            db_check_messages = [
              'check_conceptual_exam_is_unique',
              'check_descriptive_exam_is_unique',
              'check_absence_justification_student_is_unique'
            ]

            raise exception unless db_check_messages.any? { |check_message|
              exception.message.include?(check_message)
            }
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
end
