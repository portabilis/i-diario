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
      audits = record.audits
                     .where(action: 'update')
                     .where('audited_changes ILIKE :foreign_key', foreign_key: "%#{foreign_key}%")

      return if audits.empty?

      audits.any? { |audit| audit.audited_changes[foreign_key.to_s] == [secondary_teacher_id, @main_teacher.id] }
    end

    def discardable?(klass)
      klass.respond_to?(:with_discarded)
    end
  end
end
