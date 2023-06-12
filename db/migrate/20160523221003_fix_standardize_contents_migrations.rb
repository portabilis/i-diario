class FixStandardizeContentsMigrations < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DELETE
      FROM contents_lesson_plans
      WHERE EXISTS (
      SELECT *
      FROM lesson_plans
      WHERE contents_lesson_plans.lesson_plan_id = lesson_plans.id
      AND old_contents IS NOT NULL )
    SQL
    LessonPlan.where("created_at::date < '2016-05-21'::date ").where(LessonPlan.arel_table[:old_contents].not_eq(nil)).each do |lesson_plan|
      lesson_plan.contents = lesson_plan.old_contents.split(/\s*[,;]\s* | [\r\n]+ /x).map(&:strip).reject(&:blank?).map{|v| Content.find_or_create_by!(description: v)}
      lesson_plan.without_auditing do
        lesson_plan.save!
      end
    end
    execute <<-SQL
      DELETE
      FROM contents_teaching_plans
      WHERE EXISTS (
      SELECT *
      FROM teaching_plans
      WHERE contents_teaching_plans.teaching_plan_id = teaching_plans.id
      AND old_contents IS NOT NULL )
    SQL
    TeachingPlan.where("created_at::date < '2016-05-21'::date ").where(TeachingPlan.arel_table[:old_contents].not_eq(nil)).each do |teaching_plan|
      teaching_plan.contents = teaching_plan.old_contents.split(/\s*[,;]\s* | [\r\n]+ /x).map(&:strip).reject(&:blank?).map{|v| Content.find_or_create_by!(description: v)}
      teaching_plan.without_auditing do
        teaching_plan.save!
      end
    end
  end
end
