class StudentEnrollmentExemptedDisciplinesSynchronizer
  def self.synchronize!(synchronization)
    new(synchronization).synchronize!
  end

  def initialize(synchronization)
    self.synchronization = synchronization
  end

  def synchronize!
    update_records api.fetch["dispensas"]
  end

  protected

  attr_accessor :synchronization

  def api
    IeducarApi::StudentEnrollmentExemptedDisciplines.new(synchronization.to_api)
  end

  def update_records(collection)
    ActiveRecord::Base.transaction do
      dispensed_discipline_ids_to_keep = []

      collection.each do |record|
        student_enrollment_id = StudentEnrollment.find_by_api_code(record["matricula_id"]).try(&:id)
        discipline_id = Discipline.find_by_api_code(record["disciplina_id"]).try(&:id)

        if student_enrollment_id.present? && discipline_id.present?
          dispensed_disciplines = StudentEnrollmentExemptedDiscipline.find_or_create_by(student_enrollment_id: student_enrollment_id,
                                                                                        discipline_id: discipline_id)
          dispensed_disciplines.update_attribute(:steps, record["etapas"])

          dispensed_discipline_ids_to_keep << dispensed_disciplines.id
        end
      end

      destroy_inexisting_dispensed_disciplines(dispensed_discipline_ids_to_keep)
    end
  end

  def destroy_inexisting_dispensed_disciplines(dispensed_discipline_ids_to_keep)
    StudentEnrollmentExemptedDiscipline.where.not(id: dispensed_discipline_ids_to_keep).destroy_all
  end
end
