require 'rails_helper'

RSpec.describe ConceptualExamHelper, type: :helper do
  describe '#any_student_exempted_from_discipline?' do
    let(:conceptual_exam) { build(:conceptual_exam) }

    before { assign(:conceptual_exam, conceptual_exam) }

    context 'when at least one value is marked as exempted_discipline' do
      it 'returns true' do
        conceptual_exam.conceptual_exam_values.build(
          attributes_for(:conceptual_exam_value, exempted_discipline: true)
        )

        expect(helper.any_student_exempted_from_discipline?).to eq(true)
      end
    end

    context 'when no value is marked as exempted_discipline' do
      it 'returns false' do
        conceptual_exam.conceptual_exam_values.build(
          attributes_for(:conceptual_exam_value, exempted_discipline: false)
        )

        expect(helper.any_student_exempted_from_discipline?).to eq(false)
      end
    end
  end

  describe '#any_student_in_dependence?' do
    let(:student) { create(:student) }
    let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
    let(:discipline) { create(:discipline) }
    let(:conceptual_exam) { build(:conceptual_exam, student: student, classroom: classroom) }

    before { assign(:conceptual_exam, conceptual_exam) }

    context 'when @conceptual_exam is nil' do
      before { assign(:conceptual_exam, nil) }

      it 'returns false' do
        expect(helper.any_student_in_dependence?).to eq(false)
      end
    end

    context 'when the student has no matching enrollment for the classroom' do
      it 'returns false' do
        expect(helper.any_student_in_dependence?).to eq(false)
      end
    end

    context 'when the student is enrolled in the classroom but has no dependence' do
      it 'returns false' do
        enrollment = create(:student_enrollment, student: student)
        classrooms_grade = create(:classrooms_grade, classroom: classroom)
        create(
          :student_enrollment_classroom,
          classrooms_grade: classrooms_grade,
          student_enrollment: enrollment
        )

        expect(helper.any_student_in_dependence?).to eq(false)
      end
    end

    context 'when the student has a dependence record for the classroom' do
      it 'returns true' do
        enrollment = create(:student_enrollment, student: student)
        classrooms_grade = create(:classrooms_grade, classroom: classroom)
        create(
          :student_enrollment_classroom,
          classrooms_grade: classrooms_grade,
          student_enrollment: enrollment
        )
        create(:student_enrollment_dependence, student_enrollment: enrollment, discipline: discipline)

        expect(helper.any_student_in_dependence?).to eq(true)
      end
    end

    context 'when the dependence belongs to an enrollment from another classroom' do
      it 'returns false (it filters by classroom to avoid picking the wrong enrollment)' do
        other_classroom = create(:classroom, :with_classroom_semester_steps)
        enrollment = create(:student_enrollment, student: student)
        classrooms_grade = create(:classrooms_grade, classroom: other_classroom)
        create(
          :student_enrollment_classroom,
          classrooms_grade: classrooms_grade,
          student_enrollment: enrollment
        )
        create(:student_enrollment_dependence, student_enrollment: enrollment, discipline: discipline)

        expect(helper.any_student_in_dependence?).to eq(false)
      end
    end
  end

  describe '#conceptual_exam_dependence_discipline_ids' do
    let(:student) { create(:student) }
    let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
    let(:discipline_a) { create(:discipline) }
    let(:discipline_b) { create(:discipline) }
    let(:conceptual_exam) { build(:conceptual_exam, student: student, classroom: classroom) }
    let(:enrollment) { create(:student_enrollment, student: student) }

    before do
      assign(:conceptual_exam, conceptual_exam)

      classrooms_grade = create(:classrooms_grade, classroom: classroom)
      create(
        :student_enrollment_classroom,
        classrooms_grade: classrooms_grade,
        student_enrollment: enrollment
      )
    end

    it 'returns an empty Set when the student has no dependence' do
      result = helper.conceptual_exam_dependence_discipline_ids

      expect(result).to be_a(Set)
      expect(result).to be_empty
    end

    it 'returns a Set containing the dependence discipline ids' do
      create(:student_enrollment_dependence, student_enrollment: enrollment, discipline: discipline_a)
      create(:student_enrollment_dependence, student_enrollment: enrollment, discipline: discipline_b)

      result = helper.conceptual_exam_dependence_discipline_ids

      expect(result).to contain_exactly(discipline_a.id, discipline_b.id)
    end

    it 'memoizes the result across calls within the same request' do
      create(:student_enrollment_dependence, student_enrollment: enrollment, discipline: discipline_a)

      first_call = helper.conceptual_exam_dependence_discipline_ids
      # Cria uma dependência nova após a primeira chamada — não deve aparecer no resultado.
      create(:student_enrollment_dependence, student_enrollment: enrollment, discipline: discipline_b)
      second_call = helper.conceptual_exam_dependence_discipline_ids

      expect(second_call).to contain_exactly(discipline_a.id)
      expect(second_call.object_id).to eq(first_call.object_id)
    end
  end
end
