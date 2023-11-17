class ListGradesByStepService
  def initialize(step)
    @step = step
  end

  def self.call(step, to_json = true)
    new(step).call(to_json)
  end

  def call(to_json = true)
    fetch_grades(to_json)
  end

  private

  def fetch_grades(to_json)
    case @step
    when 'adult_and_youth_education'
      to_json ? AdultAndYouthEducations.to_select : AdultAndYouthEducations.to_select(false)
    when 'elementary_school'
      to_json ? ElementaryEducations.to_select : ElementaryEducations.to_select(false)
    when 'child_school'
      if GeneralConfiguration.current.group_children_education
        to_json ? GroupChildEducations.to_select : GroupChildEducations.to_select(false)
      else
        to_json ? ChildEducations.to_select : ChildEducations.to_select(false)
      end
    end
  end
end
