FactoryGirl.define do
  factory :teaching_plan do
    year 2015
    school_term_type SchoolTermTypes::BIMESTER
    school_term      Bimesters::FIRST_BIMESTER
    contents {[FactoryGirl.create(:content)]}
    unity
    grade
  end

  factory :teaching_plan_without_contents, class: TeachingPlan do
    year 2015
    school_term_type SchoolTermTypes::SEMESTER
    school_term      Semesters::FIRST_SEMESTER
    unity
    grade
  end
end
