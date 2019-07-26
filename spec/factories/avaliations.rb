FactoryGirl.define do
  factory :avaliation do
    discipline
    classroom
    test_setting
    association :school_calendar, factory: :school_calendar_with_one_step

    test_date '03/02/2020'
    classes { rand(1..5).to_s }
    description { Faker::Lorem.unique.sentence }

    factory :current_avaliation do
      test_date { Date.current }
      association :school_calendar, factory: :current_school_calendar_with_one_step
      association :classroom, factory: :classroom_numeric_and_concept
    end

    after(:build) do |avaliation|
      teacher_discipline_classroom = create(
        :teacher_discipline_classroom,
        classroom: avaliation.classroom,
        discipline: avaliation.discipline
      )

      avaliation.teacher_id = teacher_discipline_classroom.teacher.id
    end
  end
end
