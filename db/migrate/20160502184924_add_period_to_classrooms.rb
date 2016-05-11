class AddPeriodToClassrooms < ActiveRecord::Migration
  def change
    add_column :classrooms, :period, :string
  end
end
