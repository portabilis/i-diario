FactoryGirl.define do
  factory :avaliation_recovery_diary_record do
    avaliation
    association :recovery_diary_record, factory: [
      :recovery_diary_record,
      :with_teacher_discipline_classroom,
      :with_students
    ]

    transient do
      teacher nil
    end

    trait :with_teacher_discipline_classroom do
      avaliation nil
      recovery_diary_record nil

      after(:build) do |avaliation_recovery_diary_record, evaluator|
        teacher = evaluator.teacher || create(:teacher)
        avaliation = create(:avaliation, :with_teacher_discipline_classroom, teacher: teacher)
        recovery_diary_record = create(
          :recovery_diary_record,
          :with_students,
          classroom: avaliation.classroom,
          discipline: avaliation.discipline,
          teacher: teacher,
          teacher_id: teacher.id
        )

        avaliation_recovery_diary_record.avaliation = avaliation
        avaliation_recovery_diary_record.recovery_diary_record = recovery_diary_record
      end
    end
  end
end
