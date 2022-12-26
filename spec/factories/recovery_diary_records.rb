FactoryGirl.define do
  factory :recovery_diary_record do
    discipline

    association :classroom, factory: [:classroom, :score_type_numeric_and_concept]

    unity { classroom.unity }

    recorded_at { Date.current }

    transient do
      students_count 5
      teacher nil
    end

    trait :with_classroom_semester_steps do
      association :classroom, factory: [
        :classroom,
        :score_type_numeric_and_concept_create_rule,
        :with_classroom_semester_steps
      ]
    end

    trait :with_teacher_discipline_classroom do
      after(:build) do |recovery_diary_record, evaluator|
        teacher = Teacher.find(recovery_diary_record.teacher_id) if recovery_diary_record.teacher_id.present?
        teacher ||= evaluator.teacher || create(:teacher)
        recovery_diary_record.teacher_id = teacher.id if recovery_diary_record.teacher_id.blank?

        create(
          :teacher_discipline_classroom,
          classroom: recovery_diary_record.classroom,
          discipline: recovery_diary_record.discipline,
          teacher: teacher
        )
      end
    end

    trait :with_students do
      after(:build) do |recovery_diary_record, evaluator|
        evaluator.students_count.times do
          recovery_diary_record_student = build(
            :recovery_diary_record_student,
            recovery_diary_record: recovery_diary_record
          )
          recovery_diary_record.students << recovery_diary_record_student
        end
      end
    end
  end
end
