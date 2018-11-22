class ExemptedDisciplinesInStep
  def self.discipline_ids(classroom_id, step_number)
    new.discipline_ids(classroom_id, step_number)
  end

  def discipline_ids(classroom_id, step_number)
    SpecificStep.where(classroom_id: classroom_id)
                .where("not (? = ANY(string_to_array(used_steps, ',')::integer[]))", step_number)
                .where.not(used_steps: '')
                .pluck(:discipline_id)
  end
end
