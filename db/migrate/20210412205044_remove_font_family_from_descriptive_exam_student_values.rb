class RemoveFontFamilyFromDescriptiveExamStudentValues < ActiveRecord::Migration[4.2]
  def change
    DescriptiveExamStudent.where("value ILIKE '%font-family:%'").each do |descriptive_exam_student|
      inline_style = /style=\"([^"]*)"/m if descriptive_exam_student.value.match?(/style=\"([^"]*)"/m)
      tag_style = /<style.*?<\/style>/m if descriptive_exam_student.value.match?(/<style.*?<\/style>/m)

      next unless inline_style || tag_style

      descriptive_exam_student.value = descriptive_exam_student.value.gsub(inline_style, '') if inline_style
      descriptive_exam_student.value = descriptive_exam_student.value.gsub(tag_style, '') if tag_style
      descriptive_exam_student.save!
    end
  end
end
