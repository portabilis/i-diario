FactoryGirl.define do
  factory :complementary_exam_setting do
    sequence(:description) { |n| "Desc #{n}" }
    sequence(:initials) { |n| "I#{n}" }
    affected_score(AffectedScoreTypes::STEP_AVERAGE)
    calculation_type(CalculationTypes::SUM)
    maximum_score(10)
    number_of_decimal_places(1)
  end
end
