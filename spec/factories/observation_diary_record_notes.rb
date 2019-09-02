FactoryGirl.define do
  factory :observation_diary_record_note do
    observation_diary_record

    description { Faker::Lorem.sentence }
  end
end
