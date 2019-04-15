FactoryGirl.define do
  factory :knowledge_area_lesson_plan do
    lesson_plan

    after(:build) do |knowledge_area_lesson_plan|
      knowledge_area = nil
      teacher = create(:teacher)
      knowledge_area_lesson_plan.teacher_id = teacher.id
      knowledge_area_lesson_plan_knowledge_area = build(
        :knowledge_area_lesson_plan_knowledge_area,
        knowledge_area_lesson_plan: knowledge_area_lesson_plan
      )

      if knowledge_area_lesson_plan.knowledge_area_ids.present?
        knowledge_area = KnowledgeArea.find(knowledge_area_lesson_plan.knowledge_area_ids)
        knowledge_area_lesson_plan_knowledge_area.knowledge_area = knowledge_area
      else
        knowledge_area = knowledge_area_lesson_plan_knowledge_area.knowledge_area
      end

      discipline = create(:discipline, knowledge_area: knowledge_area)

      create(
        :teacher_discipline_classroom,
        discipline: discipline,
        teacher: teacher
      )
    end
  end
end
