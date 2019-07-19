FactoryGirl.define do
  factory :complementary_exam do
    discipline
    classroom
    unity { classroom.unity }
    association :complementary_exam_setting, factory: :complementary_exam_setting_with_two_grades

    recorded_at { Date.current }

    after(:build) do |complementary_exam|
      complementary_exam.students << build(:complementary_exam_student, complementary_exam: complementary_exam)

      teacher_discipline_classroom = create(
        :teacher_discipline_classroom,
        classroom: complementary_exam.classroom,
        discipline: complementary_exam.discipline
      )

      complementary_exam.teacher_id = teacher_discipline_classroom.teacher.id
    end
  end
end
