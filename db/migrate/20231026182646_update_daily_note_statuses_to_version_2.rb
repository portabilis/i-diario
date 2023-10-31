class UpdateDailyNoteStatusesToVersion2 < ActiveRecord::Migration[5.0]
  def change
    replace_view :daily_note_statuses, version: 2, revert_to_version: 1
  end
end
