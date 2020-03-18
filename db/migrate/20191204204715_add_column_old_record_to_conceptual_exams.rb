class AddColumnOldRecordToConceptualExams < ActiveRecord::Migration
  def change
    add_column :conceptual_exams, :old_record, :boolean, default: true
  end
end
