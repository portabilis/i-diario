FactoryGirl.define do
  factory :test_setting do
    sequence(:year) { |n| 2020 + n }
    maximum_score 10
    number_of_decimal_places 2
    fix_tests false
  end
end