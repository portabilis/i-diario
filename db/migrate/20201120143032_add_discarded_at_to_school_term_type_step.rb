class AddDiscardedAtToSchoolTermTypeStep < ActiveRecord::Migration[4.2]
  def change
    add_column :school_term_type_steps, :discarded_at, :datetime
  end
end
