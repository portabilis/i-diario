class StudentDependenciesDiscarder
  def self.discard(entity_id, student_enrollment_id)
    AvaliationExemptionsDiscardWorker.perform_async(entity_id, student_enrollment_id)
    ObservationDiaryRecordsDiscardWorker.perform_async(entity_id, student_enrollment_id)
    ConceptualExamsDiscardWorker.perform_async(entity_id, student_enrollment_id)
    AbsenceJustificationsDiscardWorker.perform_async(entity_id, student_enrollment_id)
  end

  def self.undiscard(entity_id, student_enrollment_id)
    AvaliationExemptionsUndiscardWorker.perform_async(entity_id, student_enrollment_id)
    ObservationDiaryRecordsUndiscardWorker.perform_async(entity_id, student_enrollment_id)
    ConceptualExamsUndiscardWorker.perform_async(entity_id, student_enrollment_id)
    AbsenceJustificationsUndiscardWorker.perform_async(entity_id, student_enrollment_id)
  end
end
