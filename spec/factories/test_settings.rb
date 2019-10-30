FactoryGirl.define do
  factory :test_setting do
    sequence(:year) { |n| 2020 + n }
    exam_setting_type ExamSettingTypes::GENERAL
    maximum_score 10
    number_of_decimal_places { rand(0..2) }
    average_calculation_type AverageCalculationTypes::ARITHMETIC

    factory :test_setting_with_sum_calculation_type do |_test_setting|
      average_calculation_type AverageCalculationTypes::SUM

      after(:build) do |test_setting|
        test_setting.tests.build(
          attributes_for(
            :test_setting_test,
            weight: test_setting.maximum_score,
            allow_break_up: false
          )
        )
      end
    end

    factory :test_setting_with_sum_calculation_type_that_allow_break_up do |_test_setting|
      average_calculation_type AverageCalculationTypes::SUM

      after(:build) do |test_setting|
        test_setting.tests.build(
          attributes_for(
            :test_setting_test,
            weight: test_setting.maximum_score,
            allow_break_up: true
          )
        )
      end
    end
  end
end
