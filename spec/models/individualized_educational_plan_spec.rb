require 'rails_helper'

RSpec.describe IndividualizedEducationalPlan, type: :model do
  describe 'associations' do
    it { expect(subject).to belong_to(:student) }
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
    it { expect(subject).to validate_presence_of(:year) }
    it { expect(subject).to validate_presence_of(:elaborated_at) }

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
      existing = create(:individualized_educational_plan, year: Date.current.year - 1,
                                                          elaborated_at: Date.new(Date.current.year - 1, 3, 10))
      other_year = build(
        :individualized_educational_plan,
        student: existing.student,
        year: Date.current.year,
        elaborated_at: Date.current
      )

      expect(other_year).to be_valid
    end

    it 'rejects an elaboration date in the future' do
      plan = build(:individualized_educational_plan, year: Date.current.year, elaborated_at: Date.current + 1)

      expect(plan).not_to be_valid
      expect(plan.errors[:elaborated_at]).to eq([I18n.t('errors.messages.not_in_future')])
    end

    it 'accepts today as the elaboration date' do
      plan = build(:individualized_educational_plan, year: Date.current.year, elaborated_at: Date.current)

      expect(plan).to be_valid
    end

    it 'accepts the first day of the plan school year' do
      plan = build(:individualized_educational_plan, year: Date.current.year,
                                                     elaborated_at: Date.new(Date.current.year, 1, 1))

      expect(plan).to be_valid
    end

    # Passada, mas de outro ano: a regra de data futura não pega, a de ano sim.
    it 'rejects a past elaboration date outside the plan school year' do
      plan = build(:individualized_educational_plan, year: Date.current.year,
                                                     elaborated_at: Date.new(Date.current.year - 1, 12, 15))

      expect(plan).not_to be_valid
      expect(plan.errors[:elaborated_at]).to eq(
        [I18n.t(
          'activerecord.errors.models.individualized_educational_plan.attributes.elaborated_at.not_in_plan_year',
          year: Date.current.year
        )]
      )
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

  # Filtro/cascata do index: turma filtrada = aluno cursando hoje ∪ turma autora. Enturmação
  # encerrada (ou de um dia) numa turma que não contribuiu NÃO deve trazer o aluno.
  describe '.by_classroom_id' do
    let(:entity) { Entity.find_by(domain: 'test.host') }

    around(:each) { |example| entity.using_connection { example.run } }

    let(:classroom) { create(:classroom) }

    def enroll(student, target_classroom, left_at: '')
      cg = create(:classrooms_grade, classroom: target_classroom)
      se = create(:student_enrollment, student: student)
      create(:student_enrollment_classroom, student_enrollment: se, classrooms_grade: cg, left_at: left_at)
    end

    it 'includes the plan of a student currently attending the classroom' do
      plan = create(:individualized_educational_plan)
      enroll(plan.student, classroom)

      expect(described_class.by_classroom_id(classroom.id)).to contain_exactly(plan)
    end

    it 'excludes the plan when the student left the classroom and it did not author a version' do
      plan = create(:individualized_educational_plan)
      enroll(plan.student, classroom, left_at: 1.day.ago.to_date.to_s)

      expect(described_class.by_classroom_id(classroom.id)).to be_empty
    end

    it 'includes the plan authored by the classroom even if the student no longer attends it' do
      plan = create(:individualized_educational_plan)
      create(:iep_version, iep: plan, classroom: classroom, active: true, published_at: Time.current)

      expect(described_class.by_classroom_id(classroom.id)).to contain_exactly(plan)
    end
  end
end
