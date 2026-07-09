require 'spec_helper'

RSpec.describe DailyNotesController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  describe '#reload_students_list' do
    # Cenário do save-fail no Diário de Avaliações: o usuário lança uma nota inválida (acima do
    # peso/valor máximo), o save falha, e o assign_attributes deixa a nota digitada em memória em
    # @daily_note.students. O reload deve REAPROVEITAR esse objeto (preservando a nota) em vez de
    # refazer a query — que traria o registro do banco sem a nota digitada e limparia o lançamento.
    let(:student) { create(:student) }
    let(:student_enrollment) { create(:student_enrollment, student: student) }
    let(:classrooms_grade) { create(:classrooms_grade) }
    let(:student_enrollment_classroom) do
      create(
        :student_enrollment_classroom,
        student_enrollment: student_enrollment,
        classrooms_grade: classrooms_grade
      )
    end
    let(:daily_note) { create(:daily_note) }

    before do
      # simula o assign_attributes: a nota inválida digitada pelo usuário fica em memória
      daily_note.students.build(student_id: student.id, note: 999)

      controller.instance_variable_set(:@daily_note, daily_note)

      allow(controller).to receive(:set_students_and_info) do
        controller.instance_variable_set(:@students, [])
        controller.instance_variable_set(:@normal_students, [])
        controller.instance_variable_set(:@dependence_students, [])
      end

      allow(controller).to receive(:set_student_enrollments_data) do
        controller.instance_variable_set(:@active, [student_enrollment_classroom.id])
        controller.instance_variable_set(:@dependencies, {})
        controller.instance_variable_set(:@exempted_from_discipline, {})
        controller.instance_variable_set(:@exempted_from_avaliation, [])
        controller.instance_variable_set(:@active_search, {})
      end

      allow(controller).to receive(:set_enrollment_classrooms).and_return(
        [
          {
            student: student,
            student_enrollment: student_enrollment,
            student_enrollment_classroom: student_enrollment_classroom
          }
        ]
      )
    end

    it 'preserves the entered note on save failure by reusing the in-memory object' do
      controller.send(:reload_students_list)

      students = controller.instance_variable_get(:@students)

      expect(students.map(&:student_id)).to eq([student.id])
      expect(students.first.note.to_i).to eq(999)
    end
  end
end
