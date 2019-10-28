FactoryGirl.define do
  factory :avaliation_exemption do
    avaliation
    student

    reason { Faker::Lorem.sentence }
  end
end
