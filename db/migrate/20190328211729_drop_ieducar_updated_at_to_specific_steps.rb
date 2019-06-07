class DropIeducarUpdatedAtToSpecificSteps < ActiveRecord::Migration
  def change
    remove_column :specific_steps, :ieducar_updated_at, :datetime
  end
end
