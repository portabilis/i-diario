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
        student_enrollment = StudentEnrollment.find_by_api_code(record["matricula_id"])
        student_enrollment_id = student_enrollment.try(&:id)
        discipline_id = Discipline.find_by_api_code(record["disciplina_id"]).try(&:id)

        if student_enrollment_id.present? && discipline_id.present?
          dispensed_disciplines = StudentEnrollmentExemptedDiscipline.find_or_create_by(student_enrollment_id: student_enrollment_id,
                                                                                        discipline_id: discipline_id)
          dispensed_disciplines.update_attribute(:steps, record["etapas"])

          dispensed_discipline_ids_to_keep << dispensed_disciplines.id
          remove_dispensed_exams(student_enrollment, discipline_id)
        end
      end

      destroy_inexisting_dispensed_disciplines(dispensed_discipline_ids_to_keep)
    end
  end

  def remove_dispensed_exams(student_enrollment, discipline_id)
    start_date = Date.today.beginning_of_year
    end_date = Date.today.end_of_year

    DailyNoteStudent.by_student_id(student_enrollment.student_id)
                    .by_discipline_id(discipline_id)
                    .by_test_date_between(start_date, end_date)
                    .delete_all

    student_conceptual_exams = ConceptualExam.where(student_id: student_enrollment.student_id)
                                              .where(recorded_at: start_date..end_date)
                                              .pluck(:id)

    ConceptualExamValue.where(discipline_id: discipline_id)
                       .where(conceptual_exam_id: student_conceptual_exams)
                       .delete_all
  end

  def destroy_inexisting_dispensed_disciplines(dispensed_discipline_ids_to_keep)
    StudentEnrollmentExemptedDiscipline.where.not(id: dispensed_discipline_ids_to_keep).destroy_all
  end
end
