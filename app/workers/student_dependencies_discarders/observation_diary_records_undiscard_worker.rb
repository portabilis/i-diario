class ObservationDiaryRecordsUndiscardWorker < BaseStudentDependenciesDiscarderWorker
  def perform(entity_id, student_id)
    super do
      undiscard_observation_diary_record_note_students(student_id)
    end
  end

  private

  def undiscard_observation_diary_record_note_students(student_id)
    classroom_id_column = 'observation_diary_records.classroom_id'
    date_column = 'observation_diary_records.date'

    note_students_to_undiscard = ObservationDiaryRecordNoteStudent.with_discarded.discarded.joins(
      joins_observation_diary_records_and_notes
    ).by_student_id(student_id).where(
      exists_enrollment_by_date_column(
        classroom_id_column,
        date_column
      ),
      student_id: student_id
    )

    observation_diary_record_notes = note_students_to_undiscard.map(&:observation_diary_record_note).compact

    undiscard_observation_diary_record_notes(observation_diary_record_notes)

    note_students_to_undiscard.undiscard_all
  end

  def undiscard_observation_diary_record_notes(observation_diary_record_notes)
    observation_diary_records = observation_diary_record_notes.uniq.map(&:observation_diary_record).compact

    undiscard_observation_diary_records(observation_diary_records)

    observation_diary_record_notes.each(&:undiscard)
  end

  def undiscard_observation_diary_records(observation_diary_records)
    observation_diary_records.uniq.each do |observation_diary_record|
      observation_diary_record.discarded_at = nil
      observation_diary_record.save!(validate: false)
    end
  end

  def joins_observation_diary_records_and_notes
    <<-SQL
      JOIN observation_diary_record_notes
        ON observation_diary_record_notes.id =
           observation_diary_record_note_students.observation_diary_record_note_id
      JOIN observation_diary_records
        ON observation_diary_records.id = observation_diary_record_notes.observation_diary_record_id
    SQL
  end
end
