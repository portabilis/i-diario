class AddColumnOwnerTeacherIdToDailyFrequencies < ActiveRecord::Migration[4.2]
  def change
    add_column :daily_frequencies, :owner_teacher_id, :integer
  end
end
