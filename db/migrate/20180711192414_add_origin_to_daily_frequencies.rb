class AddOriginToDailyFrequencies < ActiveRecord::Migration[4.2]
  def change
    add_column :daily_frequencies, :origin, :string
  end
end
