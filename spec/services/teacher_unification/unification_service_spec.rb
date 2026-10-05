require 'rails_helper'

RSpec.describe TeacherUnification::UnificationService, type: :service do
  let!(:main_teacher) { create(:teacher) }
  let!(:secondary_teacher) { create(:teacher) }
  let(:service) { described_class.new(main_teacher, [secondary_teacher]) }

  let(:classroom) { create(:classroom) }
  let(:discipline) { create(:discipline) }
  let(:grade) { create(:grade) }

  def create_link(teacher, attributes = {})
    create(
      :teacher_discipline_classroom,
      {
        api_code: 'link-1',
        teacher: teacher,
        classroom: classroom,
        discipline: discipline,
        grade: grade
      }.merge(attributes)
    )
  end

  describe '#run!' do
    context 'when the secondary teacher has only links the main teacher does not have' do
      let!(:secondary_link) { create_link(secondary_teacher) }

      it 'moves the link to the main teacher' do
        service.run!

        expect(secondary_link.reload.teacher_id).to eq(main_teacher.id)
        expect(secondary_link.teacher_api_code).to eq(main_teacher.api_code)
        expect(secondary_link).not_to be_discarded
      end

      it 'discards the secondary teacher' do
        service.run!

        expect(secondary_teacher.reload).to be_discarded
      end
    end

    context 'when the main teacher already has the same link as the secondary teacher' do
      let!(:main_link) { create_link(main_teacher) }
      let!(:repeated_link) { create_link(secondary_teacher) }
      let!(:other_link) { create_link(secondary_teacher, api_code: 'link-2', discipline: create(:discipline)) }
      let!(:daily_frequency) do
        create(:daily_frequency, :without_discipline).tap do |frequency|
          frequency.update_column(:owner_teacher_id, secondary_teacher.id)
        end
      end

      it 'does not raise' do
        expect { service.run! }.not_to raise_error
      end

      it 'discards the repeated link and keeps it on the secondary teacher' do
        service.run!

        expect(repeated_link.reload).to be_discarded
        expect(repeated_link.teacher_id).to eq(secondary_teacher.id)
        expect(main_link.reload).not_to be_discarded
      end

      it 'moves the remaining records to the main teacher' do
        service.run!

        expect(other_link.reload.teacher_id).to eq(main_teacher.id)
        expect(daily_frequency.reload.owner_teacher_id).to eq(main_teacher.id)
      end

      it 'discards the secondary teacher' do
        service.run!

        expect(secondary_teacher.reload).to be_discarded
      end
    end

    context 'when a repeated record cannot be discarded' do
      before do
        create(:user, teacher_id: main_teacher.id)
        create(:user, teacher_id: secondary_teacher.id)
      end

      it 'raises and keeps the secondary teacher kept' do
        expect { service.run! }.to raise_error(ActiveRecord::RecordNotUnique)
        expect(secondary_teacher.reload).not_to be_discarded
      end
    end
  end
end
