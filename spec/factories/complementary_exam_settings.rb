FactoryGirl.define do
  factory :complementary_exam_setting do
    description { Faker::Lorem.sentence }
    initials { Faker::Lorem.characters(2).upcase }
    affected_score { AffectedScoreTypes::STEP_AVERAGE }
    calculation_type { CalculationTypes::SUM }
    maximum_score { rand(1..10) }
    number_of_decimal_places { rand(0..2) }

    factory :complementary_exam_setting_with_two_grades do
      grades { create_list(:grade, 2) }
    end
  end
end
