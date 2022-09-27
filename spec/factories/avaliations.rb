FactoryGirl.define do
  factory :avaliation do
    discipline
    test_setting

    association :classroom, factory: [:classroom, :with_classroom_semester_steps]
    school_calendar { classroom.calendar.try(:school_calendar) || create(:school_calendar, :with_one_step) }

    test_date { Date.current }
    classes { rand(1..5).to_s }
    description { Faker::Lorem.unique.sentence }

    grade_ids { [create(
      :school_calendar_discipline_grade,
      school_calendar: school_calendar,
      discipline: discipline
    ).grade.id] }

    transient do
      teacher nil
    end

    trait :with_teacher_discipline_classroom do
      after(:build) do |avaliation, evaluator|
        teacher = Teacher.find(avaliation.teacher_id) if avaliation.teacher_id.present?
        teacher ||= evaluator.teacher || create(:teacher)
        avaliation.teacher_id = teacher.id if avaliation.teacher_id.blank?

        create(
          :teacher_discipline_classroom,
          classroom: avaliation.classroom,
          discipline: avaliation.discipline,
          teacher: teacher
        )
      end
    end
  end
end
