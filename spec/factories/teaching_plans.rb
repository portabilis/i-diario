FactoryGirl.define do
  factory :teaching_plan do
    unity
    grade
    teacher

    year Date.current.year
    school_term_type
    school_term_type_step
    methodology Faker::Lorem.sentence
    evaluation Faker::Lorem.sentence
    references Faker::Lorem.sentence
    contents { create_list(:content, 3) } # Altere o número conforme necessário
    objectives { create_list(:objective, 3) }

    before(:create) do |teaching_plan, evaluator|
      evaluator.contents.map.with_index do |content, index|
        teaching_plan.contents_created_at_position ||= {}
        teaching_plan.contents_created_at_position[content.id] = index
      end

      evaluator.objectives.map.with_index do |objective, index|
        teaching_plan.objectives_created_at_position ||= {}
        teaching_plan.objectives_created_at_position[objective.id] = index
      end
    end

    transient do
      classroom nil
      discipline nil
    end

    trait :yearly do
      school_term_type nil
      school_term_type_step nil
    end

    trait :without_contents do
      school_term_type
      school_term_type_step
      contents []
    end

    trait :with_teacher_discipline_classroom do
      after(:build) do |teaching_plan, evaluator|
        teaching_plan.teacher_id ||= teaching_plan.teacher.id
        classrooms_grade = create(:classrooms_grade, grade: teaching_plan.grade)
        classroom = evaluator.classroom || classrooms_grade.classroom
        discipline = evaluator.discipline || create(:discipline)
        grade = evaluator.grade || create(:grade)

        teaching_plan.contents_created_at_position = {}
        evaluator.contents.each_with_index do |content, index|
          teaching_plan.contents_created_at_position[content.id] = index
        end

        create(
          :teacher_discipline_classroom,
          teacher: teaching_plan.teacher,
          classroom: classroom,
          discipline: discipline,
          grade: grade
        )
      end
    end
  end
end
