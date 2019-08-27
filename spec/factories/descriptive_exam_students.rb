FactoryGirl.define do
  factory :descriptive_exam_student do
    descriptive_exam
    student

    value { Faker::Lorem.paragraph }

    transient do
      student_enrollment nil
    end

    trait :with_student_enrollment_classroom do
      after(:create) do |descriptive_exam_student, evaluator|
        student_enrollment = evaluator.student_enrollment
        student_enrollment ||= create(:student_enrollment, student: descriptive_exam_student.student)

        create(
          :student_enrollment_classroom,
          classroom: descriptive_exam_student.descriptive_exam.classroom,
          student_enrollment: student_enrollment
        )
      end
    end
  end
end
