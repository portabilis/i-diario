FactoryGirl.define do
  factory :objective do
    description { Faker::Lorem.unique.sentence }
  end
end
