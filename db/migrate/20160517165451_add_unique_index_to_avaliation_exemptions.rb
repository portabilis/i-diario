class AddUniqueIndexToAvaliationExemptions < ActiveRecord::Migration
  def change
    add_index :avaliation_exemptions, [:avaliation_id, :student_id], unique: true
  end
end
