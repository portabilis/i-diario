FactoryGirl.define do
  factory :lesson_plan do
    association :classroom, factory: [:classroom, :with_classroom_semester_steps]
    school_calendar { classroom.calendar.try(:school_calendar) || create(:school_calendar, :with_one_step) }

    contents { [create(:content)] }
    objectives { [create(:objective)] }

    before(:create) do |lesson_plan, evaluator|
      lesson_plan.contents_created_at_position = {}

      evaluator.contents.each_with_index do |content, index|
        lesson_plan.contents_created_at_position[content.id] = index
      end
    end

    before(:create) do |lesson_plan, evaluator|
      lesson_plan.objectives_created_at_position = {}

      evaluator.objectives.each_with_index do |objective, index|
        lesson_plan.objectives_created_at_position[objective.id] = index
      end
    end

    transient do
      step nil
      discipline nil
    end

    trait :without_contents do
      contents []
      objectives []
    end

    after(:build) do |lesson_plan, evaluator|
      if lesson_plan.classroom.calendar.present?
        step = evaluator.step || lesson_plan.classroom.calendar.classroom_steps.first
      end

      lesson_plan.start_at ||= Date.current
      lesson_plan.end_at ||= lesson_plan.start_at + 7.days

      teacher = Teacher.find(lesson_plan.teacher_id) if lesson_plan.teacher_id.present?
      teacher ||= lesson_plan.teacher || create(:teacher)

      if teacher.blank?
        discipline = evaluator.discipline || create(:discipline)
        teacher_discipline_classroom = create(
          :teacher_discipline_classroom,
          classroom: lesson_plan.classroom,
          discipline: discipline
        )

        lesson_plan.teacher ||= teacher_discipline_classroom.teacher
      end
    end

    trait :with_teacher_discipline_classroom do
      after(:build) do |lesson_plan, evaluator|
        teacher = Teacher.find(lesson_plan.teacher_id) if lesson_plan.teacher_id.present?
        teacher ||= lesson_plan.teacher || create(:teacher)
        lesson_plan.teacher ||= teacher
        lesson_plan.teacher_id ||= teacher.id
        discipline = evaluator.discipline || create(:discipline)

        create(
          :teacher_discipline_classroom,
          classroom: lesson_plan.classroom,
          discipline: discipline,
          teacher: teacher
        )
      end
    end

    trait :with_one_discipline_lesson_plan do
      after(:build) do |lesson_plan, evaluator|
        discipline = evaluator.discipline || create(:discipline)

        lesson_plan.build_discipline_lesson_plan(
          attributes_for(
            :discipline_lesson_plan,
            discipline_id: discipline.id,
            teacher_id: lesson_plan.teacher_id
          )
        )
      end
    end
  end
end
