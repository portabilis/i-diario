class StudentNotesInStepFetcher
  include I18n::Alchemy

  def lowest_note_in_step(student_id, classroom_id, discipline_id, step_id)
    student_notes = daily_note_students_by_student(classroom_id, discipline_id, step_id)[student_id] || []
    exempted_pairs = exempted_pairs_for(classroom_id, discipline_id, step_id)

    lowest_note = nil

    student_notes.each do |daily_note_student|
      next if exempted_pairs.include?([daily_note_student.student_id, daily_note_student.daily_note.avaliation_id])

      score = daily_note_student.recovered_note.to_f

      lowest_note = score if lowest_note.nil?

      if score < lowest_note
        lowest_note = score
      end
    end

    numeric_parser.localize(lowest_note)
  end

  private

  def avaliation_ids_for(classroom_id, discipline_id, step_id)
    @avaliation_ids_for ||= {}
    @avaliation_ids_for[[classroom_id, discipline_id, step_id]] ||=
      Avaliation.by_classroom_id(classroom_id)
                .by_discipline_id(discipline_id)
                .by_step(classroom_id, step_id)
                .pluck(:id)
  end

  def daily_note_students_by_student(classroom_id, discipline_id, step_id)
    @daily_note_students_by_student ||= {}
    @daily_note_students_by_student[[classroom_id, discipline_id, step_id]] ||=
      DailyNoteStudent.by_avaliation(avaliation_ids_for(classroom_id, discipline_id, step_id))
                      .includes(daily_note: :avaliation)
                      .group_by(&:student_id)
  end

  def exempted_pairs_for(classroom_id, discipline_id, step_id)
    @exempted_pairs_for ||= {}
    @exempted_pairs_for[[classroom_id, discipline_id, step_id]] ||=
      AvaliationExemption.where(avaliation_id: avaliation_ids_for(classroom_id, discipline_id, step_id))
                         .pluck(:student_id, :avaliation_id)
                         .to_set
  end

  def numeric_parser
    @numeric_parser ||= I18n::Alchemy::NumericParser
  end
end
