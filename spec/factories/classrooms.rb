FactoryGirl.define do
  factory :classroom do
    unity
    exam_rule
    grade

    description { Faker::Lorem.unique.sentence }
    year { Date.current.year }
    sequence(:api_code, &:to_s)
    unity_code { unity.api_code }
    period { Periods.to_a.sample[1] }

    transient do
      discipline nil
      teacher nil
      student nil
      student_enrollment nil
      school_calendar nil
    end

    trait :score_type_numeric_and_concept do
      association :exam_rule, factory: [:exam_rule, :score_type_numeric_and_concept]
    end

    trait :score_type_numeric do
      association :exam_rule, factory: :exam_rule
    end

    trait :score_type_concept do
      association :exam_rule, factory: [:exam_rule, :score_type_concept]
    end

    trait :by_discipline do
      association :exam_rule, factory: [:exam_rule, :frequency_type_by_discipline]
    end

    trait :with_teacher_discipline_classroom do
      after(:create) do |classroom, evaluator|
        discipline = evaluator.discipline || create(:discipline)
        teacher = evaluator.teacher || create(:teacher)

        create(
          :teacher_discipline_classroom,
          classroom: classroom,
          discipline: discipline,
          teacher: teacher
        )
      end
    end

    trait :with_teacher_discipline_classroom_specific do
      after(:create) do |classroom, evaluator|
        discipline = evaluator.discipline || create(:discipline)
        teacher = evaluator.teacher || create(:teacher)

        create(
          :teacher_discipline_classroom,
          classroom: classroom,
          discipline: discipline,
          teacher: teacher,
          allow_absence_by_discipline: 1,
        )
      end
    end

    trait :with_student_enrollment_classroom do
      after(:create) do |classroom, evaluator|
        student_enrollment = evaluator.student_enrollment
        student_enrollment ||= create(:student_enrollment, student: evaluator.student || create(:student))

        create(
          :student_enrollment_classroom,
          classroom: classroom,
          student_enrollment: student_enrollment
        )
      end
    end

    trait :with_classroom_trimester_steps do
      after(:create) do |classroom, evaluator|
        school_calendar = evaluator.school_calendar || create(:school_calendar, unity: classroom.unity)

        create(
          :school_calendar_classroom,
          :school_calendar_classroom_with_trimester_steps,
          classroom: classroom,
          school_calendar: school_calendar
        )
      end
    end

    trait :with_classroom_semester_steps do
      after(:create) do |classroom, evaluator|
        school_calendar = evaluator.school_calendar || create(:school_calendar, unity: classroom.unity)

        create(
          :school_calendar_classroom,
          :school_calendar_classroom_with_semester_steps,
          classroom: classroom,
          school_calendar: school_calendar
        )
      end
    end
  end
end
