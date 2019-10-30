FactoryGirl.define do
  factory :test_setting_test do
    test_setting

    description { Faker::Lorem.sentence }
    weight { test_setting.maximum_score }
  end
end
