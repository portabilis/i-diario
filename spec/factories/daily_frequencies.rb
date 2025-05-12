FactoryGirl.define do
  factory :daily_frequency do
    discipline

    unity { classroom.unity }
    school_calendar { classroom.calendar.try(:school_calendar) || create(:school_calendar) }
    association :classroom, factory: [:classroom, :with_classroom_semester_steps]

    frequency_date { Date.current }
    class_number { rand(1..5) }
    period { Periods.to_a.sample[1] }

    trait :with_teacher do
      teacher
    end

    trait :without_discipline do
      discipline nil
      class_number nil
    end

    trait :by_discipline do
      association :classroom, factory: [:classroom, :by_discipline_create_rule]
    end

    trait :with_students do
      transient do
        students_count 1
      end

      after(:create) do |daily_frequency, evaluator|
        create_list(:daily_frequency_student, evaluator.students_count, daily_frequency: daily_frequency)
      end
    end

    trait :with_teacher_discipline_classroom do
      after(:create) do |daily_frequency, evaluator|
        teacher = Teacher.find(daily_frequency.teacher_id) if daily_frequency.teacher_id.present?
        teacher ||= evaluator.teacher || create(:teacher)
        daily_frequency.teacher_id = teacher.id if daily_frequency.teacher_id.blank?

        create(
          :teacher_discipline_classroom,
          classroom: daily_frequency.classroom,
          discipline: daily_frequency.discipline,
          teacher: teacher
        )
      end
    end
  end
end
