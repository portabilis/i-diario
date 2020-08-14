class TeacherUnification
  class UnificationService < Base
    def run!
      @secondary_teachers.each do |secondary_teacher|
        Teacher.reflect_on_all_associations(:has_many).each do |association|
          next if KEEP_ASSOCIATIONS.include?(association.name)
          next if association.options[:through].present?

          secondary_teacher.send(association.name).each do |record|
            begin
              unify(record, association)
            rescue ActiveRecord::RecordNotUnique
              discard(record)
              unify(record, association)
            end
          end
        end

        discard(secondary_teacher)
      end
    end

    def unify(record, association)
      # see TeacherRelationable callback set_teacher_id
      record.teacher = @main_teacher if record.class.included_modules.include?(TeacherRelationable) && defined?(record.teacher)

      record.update_attribute(association.foreign_key, @main_teacher.id)
      return if association.name != :teacher_discipline_classrooms

      record.update_attribute(:teacher_api_code, @main_teacher.api_code)
    end

    def discard(record)
      record.update_column(:discarded_at, Time.current)
    end
  end
end
