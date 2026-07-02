# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StudentsExemptFromDiscipline, type: :service do
  context '#call' do
    let(:discipline) { create(:discipline) }
    let(:student_enrollments) { create_list(:student_enrollment, 3) }

    context 'when parameters are correct' do
      it 'should returns student_enrollments with students exempt from discipline' do
        create_enrollments_exempted(student_enrollments, discipline)
        student_enrollment_ids = student_enrollments.map(&:id)

        enrollments_hash = StudentsExemptFromDiscipline.call(
          student_enrollments: student_enrollments,
          discipline: discipline,
          step: 1
        )

        expect(enrollments_hash).to include(
          { student_enrollment_ids.first => 1 },
          { student_enrollment_ids.second => 1 },
          { student_enrollment_ids.last => 1 }
        )
        expect(enrollments_hash.size).to be(3)
      end

      it 'should not returns student_enrollments without exempt from discipline' do
        student_enrollment_ids = student_enrollments.map(&:id)

        enrollments_hash = StudentsExemptFromDiscipline.call(
          student_enrollments: student_enrollments,
          discipline: discipline,
          step: 1
        )

        expect(enrollments_hash).not_to include(
          { student_enrollment_ids.first => 1 },
          { student_enrollment_ids.second => 1 },
          { student_enrollment_ids.last => 1 }
        )
      end
    end

    context 'when parameters are not correct' do
      it 'should return error discipline parameter missing' do
        expect { StudentsExemptFromDiscipline.call(student_enrollments: student_enrollments) }.to raise_error(KeyError, 'key not found: :discipline')
      end

      it 'should return error student_enrollments parameter missing' do
        expect { StudentsExemptFromDiscipline.call(discipline: discipline) }.to raise_error(KeyError, 'key not found: :student_enrollments')
      end

      it 'should return error step parameter missing' do
        expect { StudentsExemptFromDiscipline.call(student_enrollments: student_enrollments, discipline: discipline) }.to raise_error(KeyError, 'key not found: :step')
      end

      it 'should return empty hash to params student_enrollments invalid' do
        expect(
          StudentsExemptFromDiscipline.call(
            student_enrollments: 'string',
            discipline: discipline,
            step: 1
          )
        ).to be_empty
      end

      it 'should return invalid discipline error' do
        expect do
          StudentsExemptFromDiscipline.call(
            student_enrollments: student_enrollments,
            discipline: 'string',
            step: 1
          )
        end.to raise_error(NoMethodError)
      end

      it 'should return empty hash when discipline is nil (unified frequency)' do
        create_enrollments_exempted(student_enrollments, discipline)

        expect(
          StudentsExemptFromDiscipline.call(
            student_enrollments: student_enrollments,
            discipline: nil,
            step: 1
          )
        ).to be_empty
      end

      it 'should return empty hash to params step invalid' do
        expect(
          StudentsExemptFromDiscipline.call(
            student_enrollments: 'string',
            discipline: discipline,
            step: discipline
          )
        ).to be_empty
      end
    end

    # Novos testes para frequência unificada
    context 'when checking unified frequency (discipline is nil and classroom_id is provided)' do
      let(:classroom) { create(:classroom) }
      let(:discipline1) { create(:discipline) }
      let(:discipline2) { create(:discipline) }
      let(:discipline3) { create(:discipline) }

      before do
        # Setup classroom disciplines
        create(:teacher_discipline_classroom, classroom: classroom, discipline: discipline1)
        create(:teacher_discipline_classroom, classroom: classroom, discipline: discipline2)
        create(:teacher_discipline_classroom, classroom: classroom, discipline: discipline3)
      end

      it 'should return only students exempt from ALL classroom disciplines' do
        # Student 1: exempt from ALL disciplines
        create(:student_enrollment_exempted_discipline,
               student_enrollment: student_enrollments[0],
               discipline: discipline1,
               steps: '1')
        create(:student_enrollment_exempted_discipline,
               student_enrollment: student_enrollments[0],
               discipline: discipline2,
               steps: '1')
        create(:student_enrollment_exempted_discipline,
               student_enrollment: student_enrollments[0],
               discipline: discipline3,
               steps: '1')

        # Student 2: exempt from only SOME disciplines
        create(:student_enrollment_exempted_discipline,
               student_enrollment: student_enrollments[1],
               discipline: discipline1,
               steps: '1')
        create(:student_enrollment_exempted_discipline,
               student_enrollment: student_enrollments[1],
               discipline: discipline2,
               steps: '1')
        # NOT exempt from discipline3

        # Student 3: no exemptions

        student_enrollment_ids = student_enrollments.map(&:id)

        result = StudentsExemptFromDiscipline.call(
          student_enrollments: student_enrollment_ids,
          discipline: nil,
          step: 1,
          classroom_id: classroom.id
        )

        # Only student 1 should be returned (exempt from ALL)
        expect(result.keys).to eq([student_enrollments[0].id])
        expect(result[student_enrollments[0].id]).to eq(1)
      end

      it 'should not return students exempt from only some disciplines' do
        # Student exempt from only 2 out of 3 disciplines
        create(:student_enrollment_exempted_discipline,
               student_enrollment: student_enrollments.first,
               discipline: discipline1,
               steps: '1')
        create(:student_enrollment_exempted_discipline,
               student_enrollment: student_enrollments.first,
               discipline: discipline2,
               steps: '1')
        # NOT exempt from discipline3

        student_enrollment_ids = student_enrollments.map(&:id)

        result = StudentsExemptFromDiscipline.call(
          student_enrollments: student_enrollment_ids,
          discipline: nil,
          step: 1,
          classroom_id: classroom.id
        )

        expect(result).to be_empty
      end

      it 'should return empty hash when classroom has no disciplines' do
        empty_classroom = create(:classroom)
        student_enrollment_ids = student_enrollments.map(&:id)

        result = StudentsExemptFromDiscipline.call(
          student_enrollments: student_enrollment_ids,
          discipline: nil,
          step: 1,
          classroom_id: empty_classroom.id
        )

        expect(result).to be_empty
      end
    end
  end
end

def create_enrollments_exempted(student_enrollments, discipline)
  student_enrollment_exempted_disciplines = []

  student_enrollments.each do |student_enrollment|
    enrollment_exempted = create(
      :student_enrollment_exempted_discipline,
      student_enrollment: student_enrollment,
      discipline: discipline
    )

    student_enrollment_exempted_disciplines << enrollment_exempted
  end

  student_enrollment_exempted_disciplines
end
