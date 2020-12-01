class CreateYearlySchoolTermType < ActiveRecord::Migration
  def change
    execute "INSERT INTO school_term_types (description ,steps_number) VALUES ('Anual', 1)"
  end
end
