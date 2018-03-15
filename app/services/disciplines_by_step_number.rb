class DisciplinesByStepNumber
  def initialize(classroom_id)
    @classroom_id = classroom_id
  end

  def discipline_ids_by_calendar_step(step_id)
    step_number = SchoolCalendarStep.find(step_id).to_number
    fetch_disciplines(step_number).map(&:discipline_id)
  end

  def discipline_ids_by_classroom_step(step_id)
    step_number = SchoolCalendarClassroomStep.find(step_id).to_number
    fetch_disciplines(step_number).map(&:discipline_id)
  end

  private

  def fetch_disciplines(step_number)
    SpecificStep.where(classroom_id: @classroom_id)
                .where("? = ANY(string_to_array(used_steps, ',')::integer[])", step_number)
  end
end
