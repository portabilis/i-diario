require 'rails_helper'

RSpec.describe IndividualizedEducationalPlan, type: :model do
  describe 'associations' do
    it { expect(subject).to belong_to(:student) }
    it { expect(subject).to belong_to(:unity) }
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:teacher) }
    it { expect(subject).to belong_to(:aee_teacher).class_name('Teacher') }
    it { expect(subject).to have_many(:iep_review_dates).dependent(:destroy) }
    it { expect(subject).to have_many(:iep_selected_options).dependent(:destroy) }
    it { expect(subject).to have_many(:iep_curricular_plannings).dependent(:destroy) }
    it { expect(subject).to have_many(:iep_periodic_evaluations).dependent(:destroy) }
    it { expect(subject).to have_many(:iep_versions).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:individualized_educational_plan) }

    it { expect(subject).to validate_presence_of(:student_id) }
    it { expect(subject).to validate_presence_of(:unity_id) }
    it { expect(subject).to validate_presence_of(:classroom_id) }
    it { expect(subject).to validate_presence_of(:year) }
    it { expect(subject).to validate_presence_of(:elaborated_at) }

    it 'is valid without a teacher (classroom may have no regent in i-Educar)' do
      plan = build(:individualized_educational_plan, teacher: nil)

      expect(plan).to be_valid
    end

    it 'validates uniqueness of student_id scoped to year (application-level)' do
      existing = create(:individualized_educational_plan)
      duplicate = build(
        :individualized_educational_plan,
        student: existing.student,
        year: existing.year
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:student_id]).to include(
        I18n.t('activerecord.errors.models.individualized_educational_plan.attributes.student_id.taken')
      )
    end

    it 'allows the same student in different years' do
      existing = create(:individualized_educational_plan, year: 2025)
      other_year = build(
        :individualized_educational_plan,
        student: existing.student,
        year: 2026
      )

      expect(other_year).to be_valid
    end
  end

  describe 'iep_review_dates_attributes' do
    it 'ignores blank review date rows (optional fill of the default fields)' do
      plan = build(:individualized_educational_plan)
      plan.iep_review_dates_attributes = [
        { review_date: Date.current },
        { review_date: '' },
        { review_date: nil }
      ]

      expect { plan.save! }.to change(IepReviewDate, :count).by(1)
      expect(plan.iep_review_dates.map(&:review_date)).to eq([Date.current])
    end

    it 'saves when all default review date fields are left blank' do
      plan = build(:individualized_educational_plan)
      plan.iep_review_dates_attributes = [{ review_date: '' }, { review_date: '' }, { review_date: '' }]

      expect { plan.save! }.not_to change(IepReviewDate, :count)
      expect(plan).to be_persisted
    end
  end

  describe 'finalization' do
    let(:plan) { create(:individualized_educational_plan) }

    it 'is not finalized without an active version' do
      expect(plan.finalized?).to eq(false)
    end

    it 'is finalized when there is an active version' do
      create(:iep_version, :current, iep: plan)

      expect(plan.reload.finalized?).to eq(true)
    end

    it 'active_version returns the current version' do
      active = create(:iep_version, :current, iep: plan)
      create(:iep_version, iep: plan)

      expect(plan.reload.active_version).to eq(active)
    end

    describe 'finalized/draft scopes' do
      it 'partitions plans by the existence of an active version' do
        finalized_plan = create(:individualized_educational_plan, :finalized)
        draft_plan = create(:individualized_educational_plan)

        expect(described_class.finalized).to contain_exactly(finalized_plan)
        expect(described_class.draft).to contain_exactly(draft_plan)
      end
    end
  end

  describe 'multi-select by kind' do
    let(:plan) { create(:individualized_educational_plan) }
    let!(:comm_a) { create(:iep_option, :communication_profile) }
    let!(:comm_b) { create(:iep_option, :communication_profile) }
    let!(:support) { create(:iep_option, :support_type) }

    it 'persists only ids of the given kind and ignores ids from other kinds' do
      plan.communication_profile_option_ids = [comm_a.id, comm_b.id, support.id]
      plan.save!

      expect(plan.reload.communication_profile_option_ids).to match_array([comm_a.id, comm_b.id])
    end

    it 'does not persist an option of another kind in the join' do
      plan.communication_profile_option_ids = [comm_a.id, support.id]
      plan.save!

      expect(plan.iep_selected_options.map(&:iep_option_id)).to match_array([comm_a.id])
    end

    it 'removes only the kind options absent from the update' do
      plan.communication_profile_option_ids = [comm_a.id, comm_b.id]
      plan.save!

      plan.communication_profile_option_ids = [comm_a.id]
      plan.save!

      expect(plan.reload.communication_profile_option_ids).to match_array([comm_a.id])
    end

    it 'does not affect options of another kind when updating a kind' do
      plan.support_type_option_ids = [support.id]
      plan.communication_profile_option_ids = [comm_a.id]
      plan.save!

      plan.communication_profile_option_ids = []
      plan.save!

      expect(plan.reload.support_type_option_ids).to match_array([support.id])
    end

    it 'ignores blank ids in the assignment (as they arrive from params)' do
      plan.communication_profile_option_ids = ['', comm_a.id.to_s, nil]
      plan.save!

      expect(plan.reload.communication_profile_option_ids).to match_array([comm_a.id])
    end

    it 'clears the selection when assigned nil' do
      plan.communication_profile_option_ids = [comm_a.id]
      plan.save!

      plan.communication_profile_option_ids = nil
      plan.save!

      expect(plan.reload.communication_profile_option_ids).to eq([])
    end
  end

  # A coluna "Última edição" do index usa updated_at; editar só dados aninhados (sem tocar
  # em colunas do próprio plano) precisa atualizar o updated_at via touch nas associações.
  describe 'updated_at when only nested records change' do
    let(:plan) { create(:individualized_educational_plan) }
    let(:review) { create(:iep_review_date, iep: plan) }

    it 'bumps when a curricular planning line (section 4) is added' do
      original = plan.reload.updated_at

      Timecop.travel(1.minute.from_now) do
        create(:iep_curricular_planning, iep: plan, iep_review_date: review)

        expect(plan.reload.updated_at).to be > original
      end
    end

    it 'bumps when only an accommodation option of a line changes' do
      planning = create(:iep_curricular_planning, iep: plan, iep_review_date: review)
      original = plan.reload.updated_at

      Timecop.travel(1.minute.from_now) do
        create(:iep_curricular_planning_option, iep_curricular_planning: planning,
                                                iep_option: create(:iep_option, :instructional_accommodation))

        expect(plan.reload.updated_at).to be > original
      end
    end

    it 'bumps when a periodic evaluation line (section 5) is added' do
      original = plan.reload.updated_at

      Timecop.travel(1.minute.from_now) do
        create(:iep_periodic_evaluation, iep: plan, iep_review_date: review)

        expect(plan.reload.updated_at).to be > original
      end
    end

    it 'bumps when a review date is added' do
      original = plan.reload.updated_at

      Timecop.travel(1.minute.from_now) do
        create(:iep_review_date, iep: plan)

        expect(plan.reload.updated_at).to be > original
      end
    end

    it 'bumps when a selected option (sections 2/3) changes' do
      original = plan.reload.updated_at

      Timecop.travel(1.minute.from_now) do
        create(:iep_selected_option, iep: plan)

        expect(plan.reload.updated_at).to be > original
      end
    end
  end
end
