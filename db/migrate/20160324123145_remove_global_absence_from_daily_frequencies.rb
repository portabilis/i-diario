class RemoveGlobalAbsenceFromDailyFrequencies < ActiveRecord::Migration[4.2]
  def change
    remove_column :daily_frequencies, :global_absence
  end
end
