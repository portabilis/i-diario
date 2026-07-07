class UpdateDailyNoteStatusesToVersion3 < ActiveRecord::Migration[5.0]
  def change
    replace_view :daily_note_statuses, version: 3, revert_to_version: 2
  end
end
