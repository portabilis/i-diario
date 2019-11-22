FactoryGirl.define do
  factory :observation_diary_record do
    teacher
    discipline

    association :classroom, factory: [:classroom, :with_classroom_semester_steps]
    school_calendar { classroom.calendar.try(:school_calendar) || create(:school_calendar, :with_one_step) }

    date { Date.current }

    after(:build) do |observation_diary_record|
      observation_diary_record.teacher_id ||= observation_diary_record.teacher.id
    end

    trait :with_notes do
      after(:build) do |observation_diary_record|
        observation_diary_record.notes = build_list(
          :observation_diary_record_note,
          3,
          observation_diary_record: observation_diary_record
        )
      end
    end

    trait :with_teacher_discipline_classroom do
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
end
