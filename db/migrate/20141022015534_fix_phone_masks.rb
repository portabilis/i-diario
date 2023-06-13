class FixPhoneMasks < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE users SET phone = REGEXP_REPLACE(users.phone, '-', '', 'g');
      UPDATE unities SET phone = REGEXP_REPLACE(unities.phone, '-', '', 'g');
    SQL
  end
end
