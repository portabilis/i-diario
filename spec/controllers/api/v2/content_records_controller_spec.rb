require 'rails_helper'

RSpec.describe Api::V2::ContentRecordsController, type: :controller do
  describe '#sync' do
    let(:teacher_discipline_classroom) { create(:teacher_discipline_classroom) }

    around(:each) do |example|
      Entity.find_by_domain("test.host").using_connection do
        example.run
      end
    end

    it 'destroys content record when content was not in the params' do
      content_record = create(:content_record,
                              teacher_id: teacher_discipline_classroom.teacher_id,
                              classroom_id: teacher_discipline_classroom.classroom_id)

      create(:discipline_content_record,
             content_record: content_record,
             discipline_id: teacher_discipline_classroom.discipline_id)

      params = {
        record_date: content_record.record_date.to_s,
        classroom_id: teacher_discipline_classroom.classroom_id,
        teacher_id: teacher_discipline_classroom.teacher_id,
        discipline_id: teacher_discipline_classroom.discipline_id,
        contents: nil,
        format: "json",
        locale: "en"
      }

      expect do
        xhr :post, :sync, params
      end.to change { ContentRecord.count }.to(0)
    end

    it 'creates content' do
      content_record = create(:content_record,
                              teacher_id: teacher_discipline_classroom.teacher_id,
                              classroom_id: teacher_discipline_classroom.classroom_id)

      create(:discipline_content_record,
             content_record: content_record,
             discipline_id: teacher_discipline_classroom.discipline_id)

      content_1 = { id: Content.first.id }
      content_2 = { description: 'algebra linear para crianças de até um ano' }

      params = {
        record_date: content_record.record_date.to_s,
        classroom_id: teacher_discipline_classroom.classroom_id,
        teacher_id: teacher_discipline_classroom.teacher_id,
        discipline_id: teacher_discipline_classroom.discipline_id,
        contents: [content_1, content_2],
        format: "json",
        locale: "en"
      }

      content_record.contents = content_record.contents.first(1)

      xhr :post, :sync, params

      expect(content_record.reload.contents.pluck(:description)).
        to match_array [Content.first.description, content_2[:description]]
    end
  end
end
