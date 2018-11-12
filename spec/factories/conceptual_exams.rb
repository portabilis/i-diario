FactoryGirl.define do
  factory :conceptual_exam do
    classroom
    student
    recorded_at { Time.zone.today }
    unity_id 1

    before(:create) do |conceptual_exam|
      student_enrollment = create(:student_enrollment, student: conceptual_exam.student)
      create(:student_enrollment_classroom, classroom: conceptual_exam.classroom, student_enrollment: student_enrollment)
    end

    factory :conceptual_exam_with_one_value do
      after(:build) do |conceptual_exam|
        discipline_id = create(:discipline).id
        conceptual_exam.conceptual_exam_values.build(attributes_for(:conceptual_exam_value, discipline_id: discipline_id))
      end
    end
  end
end
