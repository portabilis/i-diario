class TeacherUnification
  class ReverterService < Base
    def run!
      @secondary_teachers.each do |secondary_teacher|
        Teacher.reflect_on_all_associations(:has_many).each do |association|
          next if KEEP_ASSOCIATIONS.include?(association.name)
          next if association.options[:through].present?

          foreign_key = association.foreign_key
          discardable = discardable?(association.klass)

          association_query = association.klass
          association_query = association_query.with_discarded if discardable

          association_query.where("#{foreign_key}": @main_teacher.id).each do |record|
            next unless unified?(record, foreign_key, secondary_teacher.id)

            begin
              record.send("#{foreign_key}=", secondary_teacher.id)
              record.discarded_at = nil if discardable && record.discarded?
              record.save!(validate: false)
            rescue ActiveRecord::RecordNotUnique
            end
          end
        end

        secondary_teacher.undiscard
      end
    end

    def unified?(record, foreign_key, secondary_teacher_id)
      target_change = [secondary_teacher_id, @main_teacher.id]
      fk_str = foreign_key.to_s

      record.audits
            .where(action: 'update')
            .select(:id, :audited_changes)
            .find_each(batch_size: 100) do |audit|
        return true if audit.audited_changes[fk_str] == target_change
      end

      false
    end

    def discardable?(klass)
      klass.respond_to?(:with_discarded)
    end
  end
end
