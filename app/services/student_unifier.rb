class StudentUnifier
  def initialize(main_student, secondary_students)
    @main_student = main_student
    @secondary_students = secondary_students
  end

  def unify!
    ActiveRecord::Base.transaction do
      @secondary_students.each do |secondary_student|
        Student.reflect_on_all_associations(:has_many).each do |association|
          next if [:audits, :associated_audits].include?(association.name)

          primary_key = :id
          foreign_key = :student_id

          secondary_student.send(association.name).each do |obj|
            begin
              obj.send("#{foreign_key}=", @main_student.send(primary_key))
              obj.save!
            rescue ActiveRecord::RecordNotUnique
              obj.destroy
            end
          end
        end

        secondary_student.reload
        secondary_student.destroy

        next if secondary_student.destroyed?

        @error = "#{I18n.t('services.student_unification.delete_error')} \
          #{secondary_student.name}: #{secondary_student.errors.full_messages.to_sentence}"

        raise ActiveRecord::Rollback
      end
    end

    true
  rescue ActiveRecord::RecordInvalid => exception
    record_detail = ''

    if exception.record.class == Student
      record_detail = ": #{exception.record.student_id} - #{exception.record.name}"
    end

    @error = "#{I18n.t('services.student_unification.unification_error')}: \
      #{exception.record.class.model_name.human}#{record_detail} - #{exception.message}"

    false
  rescue ActiveRecord::DeleteRestrictionError => exception
    @error = "#{I18n.t('services.student_unification.delete_error')}: #{exception.message}"

    false
  rescue Exception => exception
    @error = "#{I18n.t('services.student_unification.unexpected_error')}: #{exception.message}"

    false
  end

  private

  attr_accessor :error
end
