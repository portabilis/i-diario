FactoryGirl.define do
  factory :observation_diary_record_note do
    association :observation_diary_record, factory: :observation_diary_record_with_notes

    description { Faker::Lorem.sentence }
  end
end
