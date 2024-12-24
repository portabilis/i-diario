require 'rails_helper'

RSpec.describe StudentEnrollmentClassroomFetcher, type: :service do
  let(:student) { create(:student) }
  let(:classroom_grade) { create(:classrooms_grade) }

  describe '#current_enrollment' do
    subject do
      described_class.new(student, classroom_grade.classroom_id, '2019-01-01', '2019-03-01')
    end

    context 'with only one enrollment' do
      it 'returns that enrollment' do
        create_student_enrollment_classroom(create_student_enrollment)
        expect(subject.current_enrollment).to eq(@student_enrollment_classroom)
      end
    end

    context 'with a relocation within the same classroom' do
      it 'returns the classroom enrollment with higher api_code' do
        student_enrollment = create_student_enrollment
        create_student_enrollment_classroom(
          student_enrollment,
          joined_at: '2019-01-01',
          left_at: '2019-02-01'
        )
        create_relocation(student_enrollment, '2019-02-01', '')

        expect(subject.current_enrollment).to eq(@student_enrollment_classroom1)
      end
    end

    context 'with a transference within the same classroom' do
      it 'returns the enrollment with higher id' do
        student_enrollment = create_student_enrollment(4)
        create_student_enrollment_classroom(
          student_enrollment,
          joined_at: '2019-01-01',
          left_at: '2019-02-01'
        )

        create_transference('2019-02-01', '')

        expect(subject.current_enrollment).to eq(@student_enrollment_classroom2)
      end
    end

    context 'with a reclassification within the same classroom' do
      it 'returns the enrollment with higher id' do
        student_enrollment = create_student_enrollment(5)
        create_student_enrollment_classroom(
          student_enrollment,
          joined_at: '2019-01-01',
          left_at: '2019-02-01'
        )

        create_reclassification('2019-02-01', '')

        expect(subject.current_enrollment).to eq(@student_enrollment_classroom3)
      end
    end

    context 'with a relocation and a transference within the same classroom' do
      it 'returns the enrollment with higher id' do
        student_enrollment = create_student_enrollment
        create_student_enrollment_classroom(
          student_enrollment,
          joined_at: '2019-01-01',
          left_at: '2019-02-01'
        )
        create_relocation(student_enrollment, '2019-02-01', '2019-02-28')
        create_transference('2019-03-01', '')

        expect(subject.current_enrollment).to eq(@student_enrollment_classroom2)
      end
    end

    context 'with a relocation and a reclassification within the same classroom' do
      it 'returns the enrollment with higher id' do
        student_enrollment = create_student_enrollment
        create_student_enrollment_classroom(
          student_enrollment,
          joined_at: '2019-01-01',
          left_at: '2019-02-01'
        )
        create_relocation(student_enrollment, '2019-02-01', '2019-02-28')
        create_reclassification('2019-03-01', '')

        expect(subject.current_enrollment).to eq(@student_enrollment_classroom3)
      end
    end

    context 'with a transference and a relocation within the same classroom' do
      it 'returns the classroom enrollment with higher api_code' do
        student_enrollment = create_student_enrollment(4)
        create_student_enrollment_classroom(
          student_enrollment,
          joined_at: '2019-01-01',
          left_at: '2019-02-01'
        )

        create_relocation(create_student_enrollment, '2019-02-01', '')

        expect(subject.current_enrollment).to eq(@student_enrollment_classroom1)
      end
    end

    context 'with a transference and a reclassification within the same classroom' do
      it 'returns the enrollment with higher id' do
        student_enrollment = create_student_enrollment(4)
        create_student_enrollment_classroom(
          student_enrollment,
          joined_at: '2019-01-01',
          left_at: '2019-02-01'
        )

        create_reclassification('2019-02-01', '')

        expect(subject.current_enrollment).to eq(@student_enrollment_classroom3)
      end
    end

    context 'with a reclassification and a relocation within the same classroom' do
      it 'returns the classroom enrollment with higher api_code' do
        student_enrollment = create_student_enrollment(5)
        create_student_enrollment_classroom(
          student_enrollment,
          joined_at: '2019-01-01',
          left_at: '2019-02-01'
        )

        create_relocation(create_student_enrollment, '2019-02-01', '')
        expect(subject.current_enrollment).to eq(@student_enrollment_classroom1)
      end
    end

    context 'with a reclassification and a transference within the same classroom' do
      it 'returns the enrollment with higher id' do
        student_enrollment = create_student_enrollment(5)
        create_student_enrollment_classroom(
          student_enrollment,
          joined_at: '2019-01-01',
          left_at: '2019-02-01'
        )
        create_transference('2019-03-01', '')
        expect(subject.current_enrollment).to eq(@student_enrollment_classroom)
      end
    end
  end

  def create_student_enrollment(status = 3)
    create(:student_enrollment, student: student, status: status)
  end

  def create_student_enrollment_classroom(
    student_enrollment,
    api_code: '1',
    joined_at: '2019-01-01',
    left_at: ''
  )
    @student_enrollment_classroom = create(
      :student_enrollment_classroom,
      student_enrollment: student_enrollment,
      classrooms_grade: classroom_grade,
      api_code: api_code,
      joined_at: joined_at,
      left_at: left_at
    )
  end

  def create_relocation(student_enrollment, joined_at, left_at)
    @student_enrollment_classroom1 = create_student_enrollment_classroom(
      student_enrollment,
      api_code: '2',
      joined_at: joined_at,
      left_at: left_at
    )
  end

  def create_transference(joined_at, left_at)
    @student_enrollment2 = create_student_enrollment

    @student_enrollment_classroom2 = create_student_enrollment_classroom(
      @student_enrollment2,
      joined_at: joined_at,
      left_at: left_at
    )
  end

  def create_reclassification(joined_at, left_at)
    @student_enrollment3 = create_student_enrollment

    @student_enrollment_classroom3 = create_student_enrollment_classroom(
      @student_enrollment3,
      joined_at: joined_at,
      left_at: left_at
    )
  end
end
