FactoryGirl.define do
  factory :teaching_plan do
    year 2015
    school_term_type SchoolTermTypes::BIMESTER
    school_term      Bimesters::FIRST_BIMESTER
    contents {[FactoryGirl.create(:content)]}
    unity
    grade
    teacher

    trait :yearly do
      school_term_type SchoolTermTypes::YEARLY
      school_term ''
    end

    after(:build) do |teaching_plan|
      classroom = create(:classroom, grade: teaching_plan.grade)

      create(
        :teacher_discipline_classroom,
        classroom: classroom,
        teacher: teaching_plan.teacher
      )
    end
  end

  factory :teaching_plan_without_contents, class: TeachingPlan do
    year 2015
    school_term_type SchoolTermTypes::SEMESTER
    school_term      Semesters::FIRST_SEMESTER
    unity
    grade
  end
end
