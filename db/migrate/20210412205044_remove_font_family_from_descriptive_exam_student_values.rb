class RemoveFontFamilyFromDescriptiveExamStudentValues < ActiveRecord::Migration
  def change
    DescriptiveExamStudent.where("value ILIKE '%font-family:%'").each do |des|
      des.value = des.value.gsub(/(?<=[(\s*)|;|'|"|])font-family:([^;>]*)(;|(?:(?!>).)*)/, '')
      des.save!
    end
  end
end
