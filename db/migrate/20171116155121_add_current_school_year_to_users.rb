class AddCurrentSchoolYearToUsers < ActiveRecord::Migration
  def change
    add_column :users, :current_school_year, :integer
  end
end
