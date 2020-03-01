class SeedTranslations < ActiveRecord::Migration
  def up
    execute File.read("#{Rails.root}/db/seeds/translations.sql")
  end

  def down
    execute 'delete from translations'
  end
end
