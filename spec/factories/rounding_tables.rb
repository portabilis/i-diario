FactoryGirl.define do
  factory :rounding_table do
    sequence(:api_code, &:to_s)
    name { Faker::Lorem.unique.sentence }
  end
end
