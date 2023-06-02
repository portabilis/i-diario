class SeedLearningObjectivesAndSkills < ActiveRecord::Migration[4.2]
  def up
    execute File.read("#{Rails.root}/db/seeds/learning_objectives_and_skills.sql")
  end

  def down
    execute 'delete from learning_objectives_and_skills'
  end
end
