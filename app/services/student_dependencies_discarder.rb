class StudentDependenciesDiscarder
  def self.discard(entity_id, student_id)
    AvaliationExemptionsDiscardWorker.perform_async(entity_id, student_id)
    ObservationDiaryRecordsDiscardWorker.perform_async(entity_id, student_id)
    ConceptualExamsDiscardWorker.perform_async(entity_id, student_id)
    DescriptiveExamStudentsDiscardWorker.perform_async(entity_id, student_id)
    AbsenceJustificationsDiscardWorker.perform_async(entity_id, student_id)
  end

  def self.undiscard(entity_id, student_id)
    AvaliationExemptionsUndiscardWorker.perform_async(entity_id, student_id)
    ObservationDiaryRecordsUndiscardWorker.perform_async(entity_id, student_id)
    ConceptualExamsUndiscardWorker.perform_async(entity_id, student_id)
    DescriptiveExamStudentsUndiscardWorker.perform_async(entity_id, student_id)
    AbsenceJustificationsUndiscardWorker.perform_async(entity_id, student_id)
  end
end
