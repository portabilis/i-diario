class StudentNotesInStepFetcher
  include I18n::Alchemy

  def lowest_note_in_step(student_id, classroom_id, discipline_id, step_id)
    classroom = Classroom.find(classroom_id)
    avaliations = Avaliation.by_classroom_id(classroom_id)
                            .by_discipline_id(discipline_id)
                            .by_step(classroom_id, step_id)
                            .ordered

    lowest_note = nil

    avaliations.each do |avaliation|
      daily_note_student = DailyNoteStudent.by_student_id(student_id)
                                           .by_avaliation(avaliation.id)
                                           .first

      next if daily_note_student.nil?
      next if daily_note_student.exempted?

      score = daily_note_student.recovered_note.to_f

      lowest_note = score if lowest_note.nil?

      if score < lowest_note
        lowest_note = score
      end
    end

    numeric_parser.localize(lowest_note)
  end

  private

  def numeric_parser
    @numeric_parser ||= I18n::Alchemy::NumericParser
  end
end
