class RevmoveSchoolTermFromTestSettings < ActiveRecord::Migration[4.2]
  def change
    remove_column :test_settings, :school_term
  end
end
