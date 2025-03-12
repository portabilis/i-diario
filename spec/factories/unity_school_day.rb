FactoryGirl.define do
  factory :unity_school_day do
    school_day { Faker::Date.forward(days: 30) }
    unity
  end
end
