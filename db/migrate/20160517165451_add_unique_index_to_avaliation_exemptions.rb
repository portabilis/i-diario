class AddUniqueIndexToAvaliationExemptions < ActiveRecord::Migration[4.2]
  def change
    add_index :avaliation_exemptions, [:avaliation_id, :student_id], unique: true
  end
end
