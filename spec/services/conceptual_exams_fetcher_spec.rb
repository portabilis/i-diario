require 'rails_helper'

RSpec.describe ConceptualExamsFetcher, type: :service do
  let(:classroom) { create(:classroom, :score_type_concept_create_rule, :with_classroom_semester_steps) }
  let(:unity) { classroom.unity }
  let(:discipline) { create(:discipline) }
  let(:teacher) { create(:teacher) }
  let(:student) { create(:student) }

  let!(:teacher_discipline_classroom) do
    create(
      :teacher_discipline_classroom,
      teacher: teacher,
      classroom: classroom,
      discipline: discipline,
      score_type: ScoreTypes::CONCEPT
    )
  end

  let!(:conceptual_exam) do
    create(
      :conceptual_exam,
      :with_student_enrollment_classroom,
      :with_one_value,
      classroom: classroom,
      teacher_id: teacher.id,
      student: student,
      discipline: discipline
    )
  end

  describe '#fetch!' do
    context 'when user is admin' do
      let(:user) { create(:user, :with_user_role_administrator) }

      subject(:result) do
        described_class.fetch!(
          user: user,
          teacher_id: teacher.id,
          unity: unity,
          classrooms: [classroom],
          disciplines: [discipline]
        )
      end

      it 'returns conceptual exams from classrooms with conceptual score type' do
        expect(result).to contain_exactly(conceptual_exam)
      end

      it 'excludes exams when discipline has numeric score type' do
        numeric_discipline = create(:discipline)
        create(
          :teacher_discipline_classroom,
          teacher: teacher,
          classroom: classroom,
          discipline: numeric_discipline,
          score_type: ScoreTypes::NUMERIC
        )

        result = described_class.fetch!(
          user: user,
          teacher_id: teacher.id,
          unity: unity,
          classrooms: [classroom],
          disciplines: [numeric_discipline]
        )

        expect(result).to be_empty
      end

      it 'includes exams when teacher discipline classroom has nil score type' do
        nil_score_discipline = create(:discipline)
        create(
          :teacher_discipline_classroom,
          teacher: teacher,
          classroom: classroom,
          discipline: nil_score_discipline,
          score_type: nil
        )

        result = described_class.fetch!(
          user: user,
          teacher_id: teacher.id,
          unity: unity,
          classrooms: [classroom],
          disciplines: [nil_score_discipline]
        )

        expect(result).to contain_exactly(conceptual_exam)
      end
    end

    context 'when user is teacher' do
      let(:user) { create(:user, :with_user_role_teacher) }

      subject(:result) do
        described_class.fetch!(
          user: user,
          teacher_id: teacher.id,
          unity: unity,
          classrooms: [classroom],
          disciplines: [discipline]
        )
      end

      it 'returns exams from the teacher' do
        expect(result).to contain_exactly(conceptual_exam)
      end

      it 'does not return exams from classrooms not assigned to the teacher' do
        other_classroom = create(:classroom, :score_type_concept_create_rule, :with_classroom_semester_steps)
        other_teacher = create(:teacher)
        other_student = create(:student)

        create(
          :teacher_discipline_classroom,
          teacher: other_teacher,
          classroom: other_classroom,
          discipline: discipline,
          score_type: ScoreTypes::CONCEPT
        )

        create(
          :conceptual_exam,
          :with_student_enrollment_classroom,
          :with_one_value,
          classroom: other_classroom,
          teacher_id: other_teacher.id,
          student: other_student,
          discipline: discipline
        )

        expect(result).to contain_exactly(conceptual_exam)
      end

      it 'does not return exams whose only matching teacher discipline classroom is discarded' do
        fetch = lambda do
          described_class.fetch!(
            user: user,
            teacher_id: teacher.id,
            unity: unity,
            classrooms: [classroom],
            disciplines: [discipline]
          )
        end

        expect(fetch.call).to contain_exactly(conceptual_exam)

        teacher_discipline_classroom.discard

        expect(fetch.call).to be_empty
      end
    end
  end
end
