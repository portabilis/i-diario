FactoryGirl.define do
  factory :content do
    description { Faker::Lorem.unique.sentence }
  end
end
