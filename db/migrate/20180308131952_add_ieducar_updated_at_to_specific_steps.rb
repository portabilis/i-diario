class AddIeducarUpdatedAtToSpecificSteps < ActiveRecord::Migration
  def change
    add_column :specific_steps, :ieducar_updated_at, :datetime
  end
end
