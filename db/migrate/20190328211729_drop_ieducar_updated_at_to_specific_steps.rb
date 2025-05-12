class DropIeducarUpdatedAtToSpecificSteps < ActiveRecord::Migration[4.2]
  def change
    remove_column :specific_steps, :ieducar_updated_at, :datetime
  end
end
