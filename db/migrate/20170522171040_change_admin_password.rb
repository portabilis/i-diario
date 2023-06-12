class ChangeAdminPassword < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE users
         SET encrypted_password = '$2a$10$yEKAdf1fGdOG2B/PQ55lZ.yjJzSo8qBTh90nXBeR4lNCLG2ywlkqu'
       WHERE id = 1;
    SQL
  end
end
