class SeedTranslationsHints < ActiveRecord::Migration
  def up
    execute File.read("#{Rails.root}/db/seeds/translations_hints.sql")
  end

  def down
    execute 'updadte translations set hint = null'
  end
end
