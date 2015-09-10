FactoryGirl.define do
  factory :test_setting do
    exam_setting_type ExamSettingTypes::GENERAL
    sequence(:year) { |n| 2020 + n }
    maximum_score 10
    number_of_decimal_places 2
    fix_tests false

    factory :test_setting_with_fixed_tests do |test_setting|
      fix_tests true

      after(:build) do |test_setting|
        test_setting.tests.build(attributes_for(:test_setting_test, weight: test_setting.maximum_score,
                                                                    allow_break_up: false))
      end
    end

    factory :test_setting_with_fixed_tests_that_allow_break_up do |test_setting|
      fix_tests true

      after(:build) do |test_setting|
        test_setting.tests.build(attributes_for(:test_setting_test, weight: test_setting.maximum_score,
                                                                    allow_break_up: true))
      end
    end
  end
end