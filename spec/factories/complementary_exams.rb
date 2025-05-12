FactoryGirl.define do
  factory :complementary_exam do
    discipline

    association :classroom, factory: [:classroom, :with_classroom_semester_steps, :score_type_numeric]
    association :complementary_exam_setting, factory: [:complementary_exam_setting, :with_two_grades, :with_teacher_discipline_classroom]
    unity { classroom.unity }

    transient do
      teacher nil
    end

    after(:build) do |complementary_exam|
      complementary_exam.students << build(:complementary_exam_student, complementary_exam: complementary_exam)

      if complementary_exam.classroom.calendar.present?
        step = complementary_exam.classroom.calendar.classroom_steps.first
      end

      if complementary_exam.recorded_at.blank?
        complementary_exam.recorded_at = Date.current
      end

      complementary_exam.step_number = step.try(:step_number) || 1 if complementary_exam.step_number.blank?
      complementary_exam.step_id = step.try(:id) if complementary_exam.step_id.blank?
    end

    trait :with_teacher_discipline_classroom do
      after(:build) do |complementary_exam, evaluator|
        teacher = Teacher.find(complementary_exam.teacher_id) if complementary_exam.teacher_id.present?
        teacher ||= evaluator.teacher || create(:teacher)
        complementary_exam.teacher_id = teacher.id if complementary_exam.teacher_id.blank?

        create(
          :teacher_discipline_classroom,
          classroom: complementary_exam.classroom,
          discipline: complementary_exam.discipline,
          teacher: teacher
        )
      end
    end
  end
end
