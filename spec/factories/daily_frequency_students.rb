FactoryGirl.define do
  factory :daily_frequency_student do
    daily_frequency
    student

    present true
    active true
  end
end
