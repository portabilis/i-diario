class StandardizeLessonPlansContents < ActiveRecord::Migration[4.2]
  def change
    rename_column :lesson_plans, :contents, :old_contents
    LessonPlan.all.each do |lesson_plan|
      lesson_plan.contents = lesson_plan.old_contents.split(/\s*[,;]\s* | [\r\n]+ /x).map(&:strip!).reject(&:blank?).map{|v| Content.find_or_create_by!(description: v)}
      lesson_plan.without_auditing do
        lesson_plan.save(validate: false)
      end
    end
  end
end
