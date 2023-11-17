class ListGradesByStepBuilder
  GRADES = {
    adult_and_youth_education: :adult_and_youth_education,
    elementary_school: :elementary_school,
    child_school: :child_school
  }

  attr_reader :step, :to_json

  def initialize(step, to_json)
    @step = step
    @to_json = to_json
  end

  def self.call(step, to_json = true)
    new(step, to_json).call
  end

  def call
    fetch_grades
  end

  private

  def fetch_grades
    send(GRADES.fetch(step.to_sym, :undefined_method))
  end

  def adult_and_youth_education
    to_json ? AdultAndYouthEducations.to_select : AdultAndYouthEducations.to_select(false)
  end

  def elementary_school
    to_json ? ElementaryEducations.to_select : ElementaryEducations.to_select(false)
  end

  def child_school
    if GeneralConfiguration.current.group_children_education
      to_json ? GroupChildEducations.to_select : GroupChildEducations.to_select(false)
    else
      to_json ? ChildEducations.to_select : ChildEducations.to_select(false)
    end
  end

  def undefined_method
    raise EventsNotCreatedError
  end
end
