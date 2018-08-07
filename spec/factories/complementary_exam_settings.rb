FactoryGirl.define do
  factory :complementary_exam_setting do
    sequence(:description) { |n| "Desc #{n}" }
    sequence(:initials) { |n| "I#{n}" }
    affected_score(AffectedScoreTypes::STEP_AVERAGE)
    calculation_type(CalculationTypes::SUM)
    maximum_score(10)
    number_of_decimal_places(1)

    factory :complementary_exam_setting_with_two_grades do
      grades { create_list(:grade, 2) }
    end
  end
end
