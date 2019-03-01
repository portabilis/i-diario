FactoryGirl.define do
  factory :descriptive_exam do
    classroom
    discipline
    step_number 1
    opinion_type OpinionTypes::BY_YEAR_AND_DISCIPLINE
  end
end
