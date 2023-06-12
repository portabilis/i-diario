class UpdateConceptualExams2019OldRecordToFalse < ActiveRecord::Migration[4.2]
  def change
    ConceptualExam.joins(
      :classroom
    ).where(
      classrooms: { year: 2019 }
    ).update_all(old_record: false)
  end
end
