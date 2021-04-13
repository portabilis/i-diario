class RemoveFontFamilyFromDescriptiveExamStudentValues < ActiveRecord::Migration
  def change
    DescriptiveExamStudent.where("value ILIKE '%font-family:%'").each do |descriptive_exam_student|
      new_value = descriptive_exam_student.value.gsub(/(?<=[(\s*)|;|'|"])font-family:([^;>]*)(;|(?:(?!>).)*)/, '')

      descriptive_exam_student.value = new_value
      descriptive_exam_student.save!
    end
  end
end
