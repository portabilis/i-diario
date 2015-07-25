FactoryGirl.define do
  factory :test_setting_test do
    description 'Example Test Settings Test'
    weight       5
    test_type   TestTypes::REGULAR
  end
end