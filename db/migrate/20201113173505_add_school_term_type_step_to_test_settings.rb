class AddSchoolTermTypeStepToTestSettings < ActiveRecord::Migration
  def change
    add_reference :test_settings, :school_term_type_step, index: true, foreign_key: true
  end
end
