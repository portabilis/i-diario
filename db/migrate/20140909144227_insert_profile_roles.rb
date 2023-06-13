class InsertProfileRoles < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DELETE FROM profiles;

      INSERT INTO profiles (role, manage_users, manage_profiles, created_at, updated_at)
      VALUES ('admin', 'f', 'f', now(), now());

      INSERT INTO profiles (role, manage_users, manage_profiles, created_at, updated_at)
      VALUES ('parent', 'f', 'f', now(), now());

      INSERT INTO profiles (role, manage_users, manage_profiles, created_at, updated_at)
      VALUES ('servant', 'f', 'f', now(), now());

      INSERT INTO profiles (role, manage_users, manage_profiles, created_at, updated_at)
      VALUES ('student', 'f', 'f', now(), now());
    SQL
  end
end
