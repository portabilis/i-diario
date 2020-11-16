class PopulateSchoolTermTypeSteps < ActiveRecord::Migration
  def change
    SchoolTermType.all.each do |school_term_type|
      1.upto(school_term_type.steps_number) do |step_number|
        SchoolTermTypeStep.create!(school_term_type_id: school_term_type.id, step_number: step_number)
      end
    end
  end
end
