require 'rails_helper'

RSpec.describe LessonPlan, type: :model do
  subject {
    build(
      :lesson_plan,
      :with_teacher_discipline_classroom
    )
  }

  describe 'associations' do
    it { expect(subject).to belong_to(:school_calendar) }
    it { expect(subject).to belong_to(:classroom) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:school_calendar) }
    it { expect(subject).to validate_presence_of(:start_at) }
    it { expect(subject).to validate_presence_of(:end_at) }

    it 'should validate if there is at least one content assigned' do
      subject = build(
        :lesson_plan,
        :with_teacher_discipline_classroom,
        :without_contents
      )

      expect(subject).to_not be_valid
      expect(subject.errors.messages[:contents]).to include('Conteúdos não pode ficar em branco')
    end
  end

  describe '#contents_ordered' do
    it 'breaks position ties by the order the contents were linked' do
      contents = create_list(:content, 3)
      lesson_plan = create(:lesson_plan, :with_teacher_discipline_classroom, contents: contents.reverse)
      join_ids = lesson_plan.contents_lesson_plans.order(:id).pluck(:id)

      # Com a mesma position em todos os vínculos, só o desempate define a ordem. Os conteúdos são
      # vinculados na ordem inversa à dos ids para a ordem de vínculo não coincidir com a dos conteúdos.
      join_ids.reverse_each { |id| lesson_plan.contents_lesson_plans.where(id: id).update_all(position: 0) }

      expect(lesson_plan.contents_ordered).to eq contents.reverse
    end
  end
end
