class AddSequenceToDisciplines < ActiveRecord::Migration
  def change
    add_column :disciplines, :sequence, :integer
  end
end
