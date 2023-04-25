class AddPeriodToClassrooms < ActiveRecord::Migration[4.2]
  def change
    add_column :classrooms, :period, :string
  end
end
