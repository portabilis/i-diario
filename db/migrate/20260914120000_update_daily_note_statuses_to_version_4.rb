class UpdateDailyNoteStatusesToVersion4 < ActiveRecord::Migration[5.0]
  def change
    replace_view :daily_note_statuses, version: 4, revert_to_version: 3
  end
end
