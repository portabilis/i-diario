# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StudentsInDependency, type: :service do
  context '#call' do
    let(:student_enrollments) { create_list(:student_enrollment, 2) }
    let(:disciplines) { create_list(:discipline, 2) }

    context 'when parameters are correct' do
      it 'should returns student_enrollments with student in dependency' do
        create_dependencies_for_disciplines(student_enrollments, disciplines)

        enrollments_hash = StudentsInDependency.call(
          student_enrollments: student_enrollments,
          disciplines: disciplines
        )

        expect(enrollments_hash).to include(
          { student_enrollments.first.id => [disciplines.first.id] },
          { student_enrollments.last.id => [disciplines.last.id] }
        )
        expect(enrollments_hash.size).to eql(2)
      end

      it 'should not returns student_enrollments with student without dependency' do
        enrollments_hash = StudentsInDependency.call(
          student_enrollments: student_enrollments,
          disciplines: disciplines
        )

        expect(enrollments_hash).to be_empty
      end
    end

    context 'when parameters are not correct' do
      it 'should return error discipline parameter missing' do
        expect { StudentsInDependency.call(student_enrollments: student_enrollments) }.to raise_error(KeyError, 'key not found: :disciplines')
      end

      it 'should return empty hash to params student_enrollments invalid' do
        expect(
          StudentsInDependency.call(
            student_enrollments: 'string',
            disciplines: disciplines
          )
        ).to be_empty
      end

      it 'should return empty hash to params disciplines invalid' do
        expect(
          StudentsInDependency.call(
            student_enrollments: student_enrollments,
            disciplines: student_enrollments
          )
        ).to be_empty
      end
    end
  end
end

def create_dependencies_for_disciplines(student_enrollments, disciplines)
  create(
    :student_enrollment_dependence,
    student_enrollment: student_enrollments.first,
    discipline: disciplines.first
  )
  create(
    :student_enrollment_dependence,
    student_enrollment: student_enrollments.last,
    discipline: disciplines.last
  )
end
