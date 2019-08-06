class ObservationDiaryRecordsDiscardWorker < BaseStudentDependenciesDiscarderWorker
  def perform(entity_id, student_id)
    super do
      discard_observation_diary_record_note_students(student_id)
    end
  end

  private

  def discard_observation_diary_record_note_students(student_id)
    classroom_id_column = 'observation_diary_records.classroom_id'
    date_column = 'observation_diary_records.date'

    note_students_to_discard = ObservationDiaryRecordNoteStudent.joins(
      observation_diary_record_note: :observation_diary_record
    ).by_student_id(student_id).where(
      not_exists_enrollment_by_date_column(
        classroom_id_column,
        date_column
      ),
      student_id: student_id
    )

    observation_diary_record_notes = []

    note_students_to_discard.each do |note_student|
      observation_diary_record_notes << note_student.observation_diary_record_note

      note_student.discard
    end

    discard_observation_diary_record_notes(observation_diary_record_notes)
  end

  def discard_observation_diary_record_notes(observation_diary_record_notes)
    observation_diary_records = []

    observation_diary_record_notes.uniq.each do |observation_diary_record_note|
      next if observation_diary_record_note.note_students.present?

      observation_diary_records << observation_diary_record_note.observation_diary_record

      observation_diary_record_note.discard
    end

    discard_observation_diary_records(observation_diary_records)
  end

  def discard_observation_diary_records(observation_diary_records)
    observation_diary_records.uniq.each do |observation_diary_record|
      next if observation_diary_record.notes.present?

      observation_diary_record.discarded_at = Time.current
      observation_diary_record.save!(validate: false)
    end
  end
end
