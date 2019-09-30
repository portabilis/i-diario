FactoryGirl.define do
  factory :knowledge_area_teaching_plan do
    teaching_plan

    transient do
      teacher nil
      classroom nil
      discipline nil
    end

    trait :with_teacher_discipline_classroom do
      teaching_plan nil

      before(:create) do |knowledge_area_teaching_plan, evaluator|
        teacher = evaluator.teacher || create(:teacher)
        knowledge_area_teaching_plan.teacher_id ||= evaluator.teacher.id if evaluator.teacher.present?
        classroom = evaluator.classroom || create(:classroom)
        discipline = evaluator.discipline || create(:discipline)
        knowledge_area_teaching_plan.knowledge_area_ids ||= discipline.knowledge_area_id

        teaching_plan = create(
          :teaching_plan,
          :with_teacher_discipline_classroom,
          teacher: teacher,
          classroom: classroom,
          discipline: discipline,
          grade: classroom.grade
        )

        knowledge_area_teaching_plan.teaching_plan = teaching_plan
      end
    end
  end
end
