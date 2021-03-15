class RevmoveSchoolTermFromTestSettings < ActiveRecord::Migration
  def change
    remove_column :test_settings, :school_term
  end
end
