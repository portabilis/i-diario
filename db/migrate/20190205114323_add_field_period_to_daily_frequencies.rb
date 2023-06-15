class AddFieldPeriodToDailyFrequencies < ActiveRecord::Migration[4.2]
  def change
    add_column :daily_frequencies, :period, :integer
  end
end
