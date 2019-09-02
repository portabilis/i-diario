require 'rails_helper'

RSpec.describe DisciplineLessonPlan, type: :model do
  subject {
    build(
      :discipline_lesson_plan,
      :with_teacher_discipline_classroom
    )
  }

  describe 'associations' do
    it { expect(subject).to belong_to(:lesson_plan) }
    it { expect(subject).to belong_to(:discipline) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:lesson_plan) }
    it { expect(subject).to validate_presence_of(:discipline) }

    context 'more than one discipline lesson plan in the same date' do
      let!(:teacher) { create(:teacher) }
      let!(:discipline) { create(:discipline) }
      let!(:classroom) {
        create(
          :classroom,
          :with_classroom_semester_steps,
          :with_teacher_discipline_classroom,
          teacher: teacher,
          discipline: discipline
        )
      }
      let!(:lesson_plan) {
        create(
          :lesson_plan,
          :with_one_discipline_lesson_plan,
          classroom: classroom,
          discipline: discipline,
          teacher_id: teacher.id
        )
      }

      it 'permits create a new discipline_lesson_plan' do
        another_lesson_plan = create(
          :lesson_plan,
          classroom: classroom,
          teacher_id: teacher.id,
          start_at: Date.current,
          end_at: Date.current + 1.day
        )
        subject = build(
          :discipline_lesson_plan,
          lesson_plan: another_lesson_plan,
          discipline: discipline,
          teacher_id: teacher.id
        )

        expect(subject).to be_valid
        expect(subject.errors[:lesson_plan].any?).to be(false)
      end
    end
  end
end
