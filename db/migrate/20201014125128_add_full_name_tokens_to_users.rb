class AddFullNameTokensToUsers < ActiveRecord::Migration[4.2]
  def up
    execute %{
      ALTER TABLE users add column fullname_tokens TSVECTOR;

      CREATE INDEX fullname_tokens_users_idx ON users USING GIST (fullname_tokens);

      UPDATE users
         SET fullname_tokens = to_tsvector('portuguese', fullname);
    }
  end

  def down
    execute 'ALTER TABLE users drop column fullname_tokens;'
  end
end
