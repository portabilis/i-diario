class AddDescricaoGeralToSchoolCalendarEvents < ActiveRecord::Migration[5.0]
  def change
    add_column :school_calendar_events, :general_description, :string
  end
end
