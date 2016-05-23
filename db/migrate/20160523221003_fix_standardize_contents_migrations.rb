class FixStandardizeContentsMigrations < ActiveRecord::Migration
  def change
    LessonPlan.where("created_at::date < '2016-05-21'::date ").each do |lesson_plan|
      lesson_plan.contents = lesson_plan.old_contents.split(/\s*[,;]\s* | [\r\n]+ /x).map(&:strip).reject(&:blank?).map{|v| Content.find_or_create_by!(description: v)}
      lesson_plan.save!
    end
    TeachingPlan.all.each do |teaching_plan|
      teaching_plan.contents = teaching_plan.old_contents.split(/\s*[,;]\s* | [\r\n]+ /x).map(&:strip!).reject(&:blank?).map{|v| Content.find_or_create_by!(description: v)}
      teaching_plan.save!
    end
  end
end
