class AddDescriptionTokenToContents < ActiveRecord::Migration[4.2]
  def up
    execute %{
      ALTER TABLE contents add column document_tokens TSVECTOR;

      CREATE INDEX document_tokens_contents_idx ON contents USING GIST (document_tokens);

      UPDATE contents
        SET document_tokens = to_tsvector('portuguese', description);
    }
  end

  def down
    execute %{
      ALTER TABLE contents drop column document_tokens;
    }
  end
end
