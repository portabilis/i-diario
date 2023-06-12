class CreateYearlySchoolTermType < ActiveRecord::Migration[4.2]
  def change
    execute "INSERT INTO school_term_types (description ,steps_number) VALUES ('Anual', 1)"
  end
end
