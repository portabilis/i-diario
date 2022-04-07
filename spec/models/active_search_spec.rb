require 'rails_helper'

RSpec.describe ActiveSearch, type: :model do
  let!(:active_search) { create(:active_search) }
  let!(:active_search_return) { create(:active_search, :with_status_return) }
  let!(:active_search_return_with_justification) { create(:active_search, :with_status_return_with_justification) }
  let!(:active_search_abandonment) { create(:active_search, :with_status_abandonment) }

  describe 'associations' do
    it { expect(subject).to belong_to(:student_enrollment) }
  end

  describe '#in_active_search?' do
    context 'when student in active search' do
      it 'responds true' do
        date = active_search.start_date
        student_enrollment_id = active_search.student_enrollment.id

        expect(subject.in_active_search?(student_enrollment_id, date)).to be_truthy
      end
    end

    context 'when student not in active search' do
      it 'responds false' do
        date = '2022-01-20'
        student_enrollment_id = active_search.student_enrollment.id

        expect(subject.in_active_search?(student_enrollment_id, date)).to be_falsey
      end
    end

    context 'when student not in active search and status return' do
      it 'responds false' do
        date = '2022-03-02'
        student_enrollment_id = active_search_return.student_enrollment.id

        expect(subject.in_active_search?(student_enrollment_id, date)).to be_falsey
      end

      it 'responds true' do
        date = '2022-03-01'
        student_enrollment_id = active_search_return.student_enrollment.id

        expect(subject.in_active_search?(student_enrollment_id, date)).to be_truthy
      end

      it 'responds with correct status' do
        expect(active_search_return.status).to eql(ActiveSearchStatus::RETURN)
      end

      it 'responds with incorrect status' do
        expect(active_search_return.status).not_to eql(ActiveSearchStatus::IN_PROGRESS)
      end
    end

    context 'when student not in active search and status return with justification' do
      it 'responds false' do
        date = '2022-02-11'
        student_enrollment_id = active_search_return_with_justification.student_enrollment.id

        expect(subject.in_active_search?(student_enrollment_id, date)).to be_falsey
      end

      it 'responds true' do
        date = '2022-02-09'
        student_enrollment_id = active_search_return_with_justification.student_enrollment.id

        expect(subject.in_active_search?(student_enrollment_id, date)).to be_truthy
      end

      it 'responds with correct status' do
        expect(active_search_return_with_justification.status).to eql(ActiveSearchStatus::RETURN_WITH_JUSTIFICATION)
      end

      it 'responds with incorrect status' do
        expect(active_search_return_with_justification.status).not_to eql(ActiveSearchStatus::IN_PROGRESS)
      end
    end

    context 'when student status abandonment' do
      it 'responds with correct status' do
        expect(active_search_abandonment.status).to eql(ActiveSearchStatus::ABANDONMENT)
      end

      it 'responds with incorrect status' do
        expect(active_search_abandonment.status).not_to eql(ActiveSearchStatus::IN_PROGRESS)
      end

      it 'responds not in active search' do
        date = '2022-05-02'
        student_enrollment_id = active_search_abandonment.id

        expect(subject.in_active_search?(student_enrollment_id, date)).to be_falsey
      end
    end
  end
end
