class StudentLowestNoteSerializer < StudentSerializer
  attributes :exempted_from_discipline, :lowest_note_in_step, :student_notes_in_step_fetcher

  def student_notes_in_step_fetcher
    @student_notes_in_step_fetcher ||= StudentNotesInStepFetcher.new
  end

  def lowest_note_in_step
    student_notes_in_step_fetcher.lowest_note_in_step(
      object.id,
      @serialization_options[:classroom],
      @serialization_options[:discipline],
      @serialization_options[:step]
    )
  end
end
