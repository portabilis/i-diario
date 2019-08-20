FactoryGirl.define do
  factory :observation_diary_record do
    classroom
    teacher
    discipline
    association :school_calendar, factory: [:school_calendar, :with_one_step]

    date '05/04/2016'

    factory :observation_diary_record_with_notes do
      after(:build) do |observation_diary_record|
        observation_diary_record.notes = build_list(
          :observation_diary_record_note,
          3,
          observation_diary_record: observation_diary_record
        )
      end
    end

    after(:build) do |observation_diary_record|
      create(
        :teacher_discipline_classroom,
        classroom: observation_diary_record.classroom,
        discipline: observation_diary_record.discipline,
        teacher: observation_diary_record.teacher
      )
    end
  end
end
