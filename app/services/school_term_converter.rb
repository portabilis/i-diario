class SchoolTermConverter
  SCHOOL_TERMS = { 4 => Bimesters, 3 => Trimesters, 2 => Semesters, 1 => Year }.freeze

  def initialize(step)
    @step = step
  end

  def self.convert(step)
    new(step).convert
  end

  def self.correct_term(school_term)
    return school_term unless school_term.end_with?(SchoolTermTypes::BIMESTER_EJA)

    "#{school_term[/.*?_/]}#{SchoolTermTypes::SEMESTER}"
  end

  def convert
    return if @step.blank?
    return if school_term_type.blank?

    school_term_type.key_for(index_of_step)
  end

  private

  def index_of_step
    school_calendar_parent.steps.find_index(@step)
  end

  def school_term_type
    @school_term_type ||= SCHOOL_TERMS[school_calendar_parent.steps.size]
  end

  def school_calendar_parent
    @school_calendar_parent ||= @step.school_calendar_parent
  end
end
