class AddSequenceToDisciplines < ActiveRecord::Migration[4.2]
  def change
    add_column :disciplines, :sequence, :integer
  end
end
