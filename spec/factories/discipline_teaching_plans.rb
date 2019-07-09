FactoryGirl.define do
  factory :discipline_teaching_plan do
    teaching_plan
    discipline

    after(:build) do |discipline_teaching_plan|
      create(
        :teacher_discipline_classroom,
        discipline: discipline_teaching_plan.discipline,
        teacher: discipline_teaching_plan.teaching_plan.teacher
      )
    end
  end
end
