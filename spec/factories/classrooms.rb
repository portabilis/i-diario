FactoryGirl.define do
  factory :classroom do
    unity

    description { Faker::Lorem.unique.sentence }
    year { Date.current.year }
    sequence(:api_code, &:to_s)
    unity_code { unity.api_code }
    period { Periods.to_a.sample[1] }

    transient do
      grade nil
      discipline nil
      teacher nil
      student nil
      student_enrollment nil
      school_calendar nil
      exam_rule { create(:exam_rule) }
    end

    trait :score_type_numeric_and_concept do
      classrooms_grades { create_list(:classrooms_grade, 2, :score_type_numeric_and_concept, exam_rule: exam_rule) }
    end

    trait :score_type_numeric do
      classrooms_grades { create_list(:classrooms_grade, 2, exam_rule: exam_rule) }
    end

    trait :score_type_concept do
      classrooms_grades { create_list(:classrooms_grade, 2, :score_type_concept, exam_rule: exam_rule) }
    end

    trait :by_discipline do
      classrooms_grades { create_list(:classrooms_grade, 2, :frequency_type_by_discipline, exam_rule: exam_rule) }
    end

    trait :score_type_numeric_and_concept_create_rule do
      classrooms_grades { create_list(:classrooms_grade, 2, :score_type_numeric_and_concept) }
    end

    trait :by_discipline_create_rule do
      classrooms_grades { create_list(:classrooms_grade, 2, :frequency_type_by_discipline) }
    end

    trait :score_type_concept_create_rule do
      classrooms_grades { create_list(:classrooms_grade, 2, :score_type_concept, exam_rule: exam_rule) }
    end

    trait :with_teacher_discipline_classroom do
      after(:create) do |classroom, evaluator|
        discipline = evaluator.discipline || create(:discipline)
        teacher = evaluator.teacher || create(:teacher)
        grade = evaluator.grade || create(:grade)

        create(
          :teacher_discipline_classroom,
          classroom: classroom,
          discipline: discipline,
          teacher: teacher,
          grade: grade
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
        classrooms_grade = create(:classrooms_grade, classroom: classroom)
        create(
          :student_enrollment_classroom,
          classrooms_grade: classrooms_grade,
          student_enrollment: student_enrollment
        )
      end
    end

    trait :with_student_enrollment_classroom_with_date do
      after(:create) do |classroom, evaluator|
        student_enrollment = evaluator.student_enrollment
        student_enrollment ||= create(:student_enrollment, student: evaluator.student || create(:student))
        classrooms_grade = create(:classrooms_grade, classroom: classroom)
        create(
          :student_enrollment_classroom,
          classrooms_grade: classrooms_grade,
          student_enrollment: student_enrollment,
          joined_at: '2017-01-01',
          left_at: '2017-04-01'
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
