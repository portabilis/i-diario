FactoryGirl.define do
  factory :knowledge_area_lesson_plan do
    lesson_plan

    transient do
      teacher nil
      classroom nil
      discipline nil
    end

    trait :with_teacher_discipline_classroom do
      lesson_plan nil

      before(:create) do |knowledge_area_lesson_plan, evaluator|
        teacher = evaluator.teacher || create(:teacher)
        knowledge_area_lesson_plan.teacher_id ||= teacher.id
        classroom = evaluator.classroom || create(:classroom, :with_classroom_semester_steps)
        first_knowledge_area_id = knowledge_area_lesson_plan.knowledge_area_ids.split(',').first
        knowledge_area_id = first_knowledge_area_id || create(:knowledge_area).id
        discipline = evaluator.discipline || create(:discipline, knowledge_area_id: knowledge_area_id)

        if knowledge_area_lesson_plan.knowledge_area_ids.blank?
          knowledge_area_lesson_plan.knowledge_area_ids = knowledge_area_id
        end

        lesson_plan = create(
          :lesson_plan,
          :with_teacher_discipline_classroom,
          teacher: teacher,
          classroom: classroom,
          discipline: discipline
        )

        knowledge_area_lesson_plan.lesson_plan = lesson_plan
      end
    end
  end
end
