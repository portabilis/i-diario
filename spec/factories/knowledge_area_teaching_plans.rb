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
        knowledge_area_teaching_plan.teacher_id ||= teacher.id
        classroom = evaluator.classroom || create(:classroom, :with_classroom_semester_steps)
        classroom_grade = create(:classrooms_grade, classroom: classroom)
        first_knowledge_area_id = knowledge_area_teaching_plan.knowledge_area_ids.split(',').first
        knowledge_area_id = first_knowledge_area_id || create(:knowledge_area).id
        discipline = evaluator.discipline || create(:discipline, knowledge_area_id: knowledge_area_id)

        if knowledge_area_teaching_plan.knowledge_area_ids.blank?
          knowledge_area_teaching_plan.knowledge_area_ids = knowledge_area_id
        end

        teaching_plan = create(
          :teaching_plan,
          :with_teacher_discipline_classroom,
          teacher: teacher,
          classroom: classroom,
          discipline: discipline,
          grade: classroom_grade.grade
        )

        knowledge_area_teaching_plan.teaching_plan = teaching_plan
      end
    end
  end
end
