FactoryGirl.define do
  factory :conceptual_exam do
    student

    association :classroom, factory: [:classroom, :score_type_concept_create_rule, :with_classroom_semester_steps]

    unity_id { classroom.unity_id }

    transient do
      discipline nil
      teacher nil
      student_enrollment nil
      grade nil
    end

    after(:build) do |conceptual_exam|
      if conceptual_exam.classroom.calendar.present?
        step = conceptual_exam.classroom.calendar.classroom_steps.first
      end

      if conceptual_exam.recorded_at.blank?
        conceptual_exam.recorded_at = Date.current
      end

      conceptual_exam.step_number = step.try(:step_number) || 1 if conceptual_exam.step_number.zero?
      conceptual_exam.step_id = step.try(:id) if conceptual_exam.step_id.blank?
    end

    trait :with_teacher_discipline_classroom do
      after(:build) do |conceptual_exam, evaluator|
        teacher = Teacher.find(conceptual_exam.teacher_id) if conceptual_exam.teacher_id.present?
        teacher ||= evaluator.teacher || create(:teacher)
        conceptual_exam.teacher_id = teacher.id if conceptual_exam.teacher_id.blank?
        discipline = evaluator.discipline || create(:discipline)
        grade = evaluator.grade || create(:grade)

        create(
          :teacher_discipline_classroom,
          classroom: conceptual_exam.classroom,
          discipline: discipline,
          teacher: teacher,
          grade: grade
        )
      end
    end

    trait :with_student_enrollment_classroom do
      after(:build) do |conceptual_exam, evaluator|
        student_enrollment = evaluator.student_enrollment
        student_enrollment ||= create(:student_enrollment, student: conceptual_exam.student)
        classrooms_grade = create(:classrooms_grade, :score_type_concept, classroom: conceptual_exam.classroom)
        create(
          :student_enrollment_classroom,
          classrooms_grade: classrooms_grade,
          student_enrollment: student_enrollment
        )
      end
    end

    trait :with_one_value do
      after(:build) do |conceptual_exam, evaluator|
        discipline = evaluator.discipline || create(:discipline)

        conceptual_exam.conceptual_exam_values.build(
          attributes_for(:conceptual_exam_value, discipline_id: discipline.id)
        )
      end
    end

    trait :without_value do
      after(:build) do |conceptual_exam, evaluator|
        discipline = evaluator.discipline || create(:discipline)

        conceptual_exam.conceptual_exam_values.build(
          attributes_for(:conceptual_exam_value, discipline_id: discipline.id, value: nil)
        )
      end
    end

  end
end
