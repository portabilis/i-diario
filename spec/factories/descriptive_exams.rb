FactoryGirl.define do
  factory :descriptive_exam do
    classroom
    discipline
    school_calendar_step
    opinion_type OpinionTypes::BY_YEAR_AND_DISCIPLINE
  end
end
