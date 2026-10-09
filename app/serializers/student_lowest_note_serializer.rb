class StudentLowestNoteSerializer < ActiveModel::Serializer
  attributes :id, :name, :sequence, :lowest_note_in_step,
             :active, :dependence, :exempted_from_discipline, :in_active_search

  def id
    object.student.id
  end

  def name
    object.student.to_s
  end

  def sequence
    @serialization_options[:sequence_by_enrollment][object.id]
  end

  def lowest_note_in_step
    @serialization_options[:notes_fetcher].lowest_note_in_step(
      object.student.id,
      @serialization_options[:classroom],
      @serialization_options[:discipline],
      @serialization_options[:step]
    )
  end

  def active
    @serialization_options[:active_enrollment_ids].include?(object.id)
  end

  def dependence
    @serialization_options[:dependencies][object.id].present?
  end

  def exempted_from_discipline
    @serialization_options[:exemptions][object.id].present?
  end

  def in_active_search
    @serialization_options[:active_search_enrollment_ids].include?(object.id)
  end
end
