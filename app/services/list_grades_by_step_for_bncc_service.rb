class ListGradesByStepForBNCCService
  def initialize(step, learning_objectives_and_skill = nil)
    @step = step
    @learning_objectives_and_skill = learning_objectives_and_skill
  end

  def self.call(step, learning_objectives_and_skill = nil, to_json = true)
    new(step, learning_objectives_and_skill).call(to_json)
  end

  def call(to_json = true)
    grades = fetch_grades(to_json)
    grades || group_children_education(to_json)
  end

  private

  def fetch_grades(to_json)
    case @step
    when 'adult_and_youth_education'
      to_json ? AdultAndYouthEducations.to_select : AdultAndYouthEducations.to_select(false)
    when 'elementary_school'
      to_json ? ElementaryEducations.to_select : ElementaryEducations.to_select(false)
    when 'child_school'
      to_json ? ChildEducations.to_select : ChildEducations.to_select(false)
    end
  end

  def group_children_education(to_json)
    return nil unless GeneralConfiguration.current.group_children_education

    to_json ? GroupChildEducations.to_select : GroupChildEducations.to_select(false)
  end
end
