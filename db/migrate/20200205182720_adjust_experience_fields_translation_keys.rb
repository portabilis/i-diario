class AdjustExperienceFieldsTranslationKeys < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      UPDATE translations
        SET key = 'activerecord.attributes.knowledge_area_lesson_plan.experience_fields'
        WHERE key = 'activerecord.attributes.lesson_plan.experience_fields';
      UPDATE translations
        SET key = 'activerecord.attributes.knowledge_area_teaching_plan.experience_fields'
        WHERE key = 'activerecord.attributes.teaching_plan.experience_fields'
    SQL
  end

  def down
    execute <<-SQL
      UPDATE translations
        SET key = 'activerecord.attributes.lesson_plan.experience_fields'
        WHERE key = 'activerecord.attributes.knowledge_area_lesson_plan.experience_fields';
      UPDATE translations
        SET key = 'activerecord.attributes.teaching_plan.experience_fields'
        WHERE key = 'activerecord.attributes.knowledge_area_teaching_plan.experience_fields'
    SQL
  end
end
