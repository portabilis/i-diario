require 'rails_helper'

RSpec.describe DestroyDuplicatedGroupedLinkService do
  let(:teacher) { create(:teacher) }
  let(:classroom) { create(:classroom) }
  let(:grade) { create(:grade) }
  let(:knowledge_area) { create(:knowledge_area, group_descriptors: true) }
  let(:regular_discipline) { create(:discipline, knowledge_area: knowledge_area) }
  let(:grouper_discipline) { create(:discipline, knowledge_area: knowledge_area, grouper: true) }

  def create_link(discipline, attrs = {})
    create(:teacher_discipline_classroom, {
      teacher: teacher,
      classroom: classroom,
      grade: grade,
      discipline: discipline,
      api_code: attrs[:api_code] || "link-#{discipline.id}"
    }.merge(attrs.except(:api_code)))
  end

  describe '.destroy_orphaned_groupers' do
    context 'when grouper has no active regular disciplines' do
      it 'destroys the orphaned grouper' do
        grouper_link = create_link(grouper_discipline, api_code: "grouper:#{grouper_discipline.id}")
        regular_link = create_link(regular_discipline)
        regular_link.discard

        described_class.call

        expect(TeacherDisciplineClassroom.where(id: grouper_link.id)).not_to exist
      end
    end

    context 'when grouper has active regular disciplines' do
      it 'does not destroy the grouper' do
        grouper_link = create_link(grouper_discipline, api_code: "grouper:#{grouper_discipline.id}")
        create_link(regular_discipline)

        described_class.call

        expect(TeacherDisciplineClassroom.where(id: grouper_link.id)).to exist
      end
    end
  end

  describe '.destroy_duplicated_groupers' do
    context 'when there are duplicated groupers' do
      it 'destroys the duplicated grouper' do
        create_link(regular_discipline)
        grouper_link_1 = create_link(grouper_discipline, api_code: "grouper:#{grouper_discipline.id}")
        grouper_link_2 = create_link(grouper_discipline, api_code: "grouper:#{grouper_discipline.id}-dup")

        described_class.call

        remaining = TeacherDisciplineClassroom.where(id: [grouper_link_1.id, grouper_link_2.id])
        expect(remaining.count).to be <= 1
      end
    end
  end
end
