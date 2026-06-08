class AddCoveringIndexToContentMvw < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def up
    # Índice Cobridor: Ajuda no WHERE e cobre os dados do SELECT pro Index-Only Scan.
    add_index :mvw_content_record_by_school_classroom_teachers, 
              [:unity_id, :record_date, :classroom_id, :teacher_id], 
              name: 'index_mvw_content_tracking_covering'
  end

  def down
    remove_index :mvw_content_record_by_school_classroom_teachers, 
                 name: 'index_mvw_content_tracking_covering'
  end
end
