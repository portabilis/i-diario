class AddCurrentSchoolYearToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :current_school_year, :integer
  end
end
