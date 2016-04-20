FactoryGirl.define do
  factory :observation_diary_record do
    date '05/04/2016'

    association :school_calendar, factory: :school_calendar_with_one_step
    teacher
    classroom
    discipline

    factory :observation_diary_record_with_notes do
      after(:build) do |observation_diary_record|
        observation_diary_record.notes = build_list(
          :observation_diary_record_note,
          3,
          observation_diary_record: observation_diary_record
        )
      end
    end
  end
end
