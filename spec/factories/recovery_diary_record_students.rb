FactoryGirl.define do
  factory :recovery_diary_record_student do
    student
    association :recovery_diary_record, factory: [
      :recovery_diary_record,
      :with_teacher_discipline_classroom,
      :with_students
    ]

    score { rand(1..10) }
  end
end
