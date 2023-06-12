class AddIeducarUpdatedAtToSpecificSteps < ActiveRecord::Migration[4.2]
  def change
    add_column :specific_steps, :ieducar_updated_at, :datetime
  end
end
