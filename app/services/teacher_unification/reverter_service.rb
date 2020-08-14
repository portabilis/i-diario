class TeacherUnification
  class ReverterService < Base
    def run!
      @secondary_teachers.each do |secondary_teacher|
        Teacher.reflect_on_all_associations(:has_many).each do |association|
          next if KEEP_ASSOCIATIONS.include?(association.name)
          next if association.options[:through].present?

          association.klass.with_discarded.where(teacher_id: @main_teacher.id).each do |record|
            next unless unified?(record, secondary_teacher.id)

            begin
              record.teacher_id = secondary_teacher.id
              record.discarded_at = nil if record.discarded?
              record.save!(validate: false)
            rescue ActiveRecord::RecordNotUnique
            end
          end
        end
      end
    end

    def unified?(record, secondary_teacher_id)
      audits = record.audits
                     .where(action: 'update')
                     .where("audited_changes ILIKE '%teacher_id:%'")

      return if audits.empty?

      audits.any? { |audit| audit.audited_changes['teacher_id'] == [secondary_teacher_id, @main_teacher.id] }
    end
  end
end
