class StudentUnification
  class ReverterService < Base
    def run!
      @secondary_students.each do |secondary_student|
        Student.reflect_on_all_associations(:has_many).each do |association|
          next if keep_associations.include?(association.name)

          discardable = discardable?(association.klass)

          association_query = association.klass
          association_query = association_query.with_discarded if discardable

          association_query.where(student_id: @main_student.id).each do |record|
            next unless unified?(record, secondary_student.id)

            begin
              record.student_id = secondary_student.id
              record.discarded_at = nil if discardable && record.discarded?
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

    def discardable?(klass)
      klass.respond_to?(:with_discarded)
    end
  end
end
