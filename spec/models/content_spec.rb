require 'rails_helper'

RSpec.describe Content, type: :model do
  describe '.by_teacher_id' do
    let(:teacher) { create(:teacher) }
    let(:other_teacher) { create(:teacher) }

    let(:content_record_content) { create(:content) }
    let(:teaching_plan_content) { create(:content) }
    let(:lesson_plan_content) { create(:content) }

    before do
      create(:content_record, :with_teacher_discipline_classroom, teacher: teacher, contents: [content_record_content])
      create(:teaching_plan, :with_teacher_discipline_classroom, teacher: teacher, contents: [teaching_plan_content])
      create(:lesson_plan, :with_teacher_discipline_classroom, teacher: teacher, contents: [lesson_plan_content])
      create(:content_record, :with_teacher_discipline_classroom, teacher: other_teacher, contents: [create(:content)])
      create(:teaching_plan, :with_teacher_discipline_classroom, teacher: other_teacher, contents: [create(:content)])
      create(:lesson_plan, :with_teacher_discipline_classroom, teacher: other_teacher, contents: [create(:content)])
      create(:content)
    end

    it 'returns the contents linked to the teacher by content records, teaching plans and lesson plans' do
      expect(Content.by_teacher_id(teacher.id)).to contain_exactly(
        content_record_content,
        teaching_plan_content,
        lesson_plan_content
      )
    end

    it 'returns a content only once when it is linked to the teacher by more than one path' do
      create(:lesson_plan, :with_teacher_discipline_classroom, teacher: teacher, contents: [content_record_content])

      expect(Content.by_teacher_id(teacher.id).to_a).to contain_exactly(
        content_record_content,
        teaching_plan_content,
        lesson_plan_content
      )
    end

    it 'filters by an array of ids so the planner starts from the primary key' do
      expect(Content.by_teacher_id(teacher.id).to_sql).to include('= ANY (ARRAY(')
    end

    it 'returns nothing for a teacher without contents' do
      expect(Content.by_teacher_id(create(:teacher).id)).to be_empty
    end

    it 'keeps only the contents of the teacher when combined with by_description' do
      teacher_content = create(:content, description: 'Leitura compartilhada')
      create(:content_record, :with_teacher_discipline_classroom, teacher: teacher, contents: [teacher_content])
      other_content = create(:content, description: 'Leitura individual')
      create(:content_record, :with_teacher_discipline_classroom, teacher: other_teacher, contents: [other_content])

      expect(Content.by_teacher_id(teacher.id).by_description('Leitura')).to contain_exactly(teacher_content)
    end
  end
end
