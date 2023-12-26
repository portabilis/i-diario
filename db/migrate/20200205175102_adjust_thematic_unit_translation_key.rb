class AdjustThematicUnitTranslationKey < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      UPDATE translations
        SET key = 'activerecord.attributes.discipline_lesson_plan.thematic_unit'
        WHERE key = 'activerecord.attributes.lesson_plan.thematic_unit';
      UPDATE translations
        SET key = 'activerecord.attributes.discipline_teaching_plan.thematic_unit'
        WHERE key = 'activerecord.attributes.teaching_plan.thematic_unit'
    SQL
  end

  def down
    execute <<-SQL
      UPDATE translations
        SET key = 'activerecord.attributes.lesson_plan.thematic_unit'
        WHERE key = 'activerecord.attributes.discipline_lesson_plan.thematic_unit';
      UPDATE translations
        SET key = 'activerecord.attributes.teaching_plan.thematic_unit'
        WHERE key = 'activerecord.attributes.discipline_teaching_plan.thematic_unit'
    SQL
  end
end
