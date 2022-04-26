class StudentLowestNoteSerializer < StudentSerializer
  attributes :exempted_from_discipline, :lowest_note_in_step

  def lowest_note_in_step
    StudentNotesInStepFetcher.new.lowest_note_in_step(
      object,
      @serialization_options[:classroom],
      @serialization_options[:discipline],
      @serialization_options[:step]
    )
  end
end
