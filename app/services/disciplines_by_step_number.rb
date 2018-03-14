class DisciplinesByStepNumber
  def self.discipline_ids(classroom_id, step_id)
    new(classroom_id, step_id).discipline_ids
  end

  def initialize(classroom_id, step_id)
    @step_id = step_id
    @classroom_id = classroom_id
  end

  def discipline_ids
    fetch_disciplines.map(&:discipline_id)
  end

  private

  def fetch_disciplines
    step_number = SchoolCalendarClassroomStep.find_by_id(@step_id).try(:to_number)
    step_number = SchoolCalendarStep.find_by_id(@step_id).to_number unless step_number
    disciplines_by_step = SpecificStep.where(classroom_id: @classroom_id)
                                      .where("? = ANY(string_to_array(used_steps, ',')::integer[])", step_number)
  end
end
