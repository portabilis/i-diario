class AddColumnOwnerTeacherIdToDailyFrequencies < ActiveRecord::Migration
  def change
    add_column :daily_frequencies, :owner_teacher_id, :integer
  end
end
