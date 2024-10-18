FactoryGirl.define do
  factory :descriptive_exam do
    discipline

    association :classroom, factory: [:classroom, :score_type_concept, :with_classroom_semester_steps]

    opinion_type OpinionTypes::BY_YEAR_AND_DISCIPLINE

    transient do
      step nil
      teacher nil
      student nil
    end

    before(:create) do |descriptive_exam, evaluator|
      if descriptive_exam.classroom.calendar.present?
        step = evaluator.step || descriptive_exam.classroom.calendar.classroom_steps.first
      end

      if descriptive_exam.recorded_at.blank?
        descriptive_exam.recorded_at = Date.current
      end

      descriptive_exam.step_number = step.try(:step_number) || 1 if descriptive_exam.step_number.zero?
      descriptive_exam.step_id ||= step.try(:id)
    end

    trait :with_teacher_discipline_classroom do
      after(:build) do |descriptive_exam, evaluator|
        teacher = Teacher.find(descriptive_exam.teacher_id) if descriptive_exam.teacher_id.present?
        teacher ||= evaluator.teacher || create(:teacher)
        descriptive_exam.teacher_id = teacher.id if descriptive_exam.teacher_id.blank?

        create(
          :teacher_discipline_classroom,
          classroom: descriptive_exam.classroom,
          discipline: descriptive_exam.discipline,
          teacher: teacher
        )
      end
    end

    trait :with_one_student do
      after(:build) do |descriptive_exam, evaluator|
        student = evaluator.student || create(:student)

        descriptive_exam.descriptive_exam_students.build(
          attributes_for(:descriptive_exam_student, student_id: student.id)
        )
      end
    end
  end
end
