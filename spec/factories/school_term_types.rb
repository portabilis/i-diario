FactoryGirl.define do
  factory :school_term_type do
    description { Faker::Lorem.sentence }
    steps_number 4
  end
end
