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
        expect {
          StudentsExemptFromDiscipline.call(
            student_enrollments: student_enrollments,
            discipline: 'string',
            step: 1
          )
        }.to raise_error(NoMethodError)
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
