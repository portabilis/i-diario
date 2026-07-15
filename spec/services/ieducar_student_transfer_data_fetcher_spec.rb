# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IeducarStudentTransferDataFetcher, type: :service do
  let(:entity) { Entity.find_by_domain('test.host') }
  let!(:ieducar_api_configuration) { create(:ieducar_api_configuration) }
  let!(:unity) { create(:unity) }
  let!(:discipline) { create(:discipline) }
  let!(:classroom) do
    create(
      :classroom,
      :with_classroom_semester_steps,
      :score_type_numeric_and_concept_create_rule,
      unity: unity
    )
  end
  let!(:student_enrollment_classroom) do
    create(
      :student_enrollment_classroom,
      classrooms_grade: classroom.classrooms_grades.first,
      joined_at: classroom.calendar.classroom_steps.first.start_at
    )
  end
  let(:student) { student_enrollment_classroom.student_enrollment.student }
  let!(:teacher_discipline_classroom) do
    create(
      :teacher_discipline_classroom,
      classroom: classroom,
      discipline: discipline,
      score_type: ScoreTypes::NUMERIC
    )
  end
  let(:teacher) { teacher_discipline_classroom.teacher }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  subject { described_class.new(student: student, classroom: classroom) }

  # Regressão issue 7960: turmas sem nota (apuração apenas por frequência) só
  # devem ter a última etapa enviada quando ela já está encerrada na data da
  # transferência, evitando aprovar o aluno com uma etapa parcial.
  describe '#post_to_ieducar! - envio da última etapa em turma sem nota' do
    let(:last_step) { classroom.calendar.classroom_steps.last }
    let(:faltas_geral_request) do
      a_request(
        :post,
        %r{http://test.ieducar.com.br/module/Api/Diario\?.*action=faltas-geral.*}
      )
    end

    before do
      classroom.first_exam_rule.update(
        score_type: ScoreTypes::DONT_USE,
        frequency_type: FrequencyTypes::GENERAL
      )

      stub_request(:post, %r{http://test.ieducar.com.br/module/Api/Diario})
        .to_return(
          status: 200,
          body: '{"msgs": [{"msg": "success", "type": "success"}], "any_error_msg": false}',
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    context 'quando o aluno foi transferido antes do encerramento da última etapa' do
      subject do
        described_class.new(
          student: student,
          classroom: classroom,
          transfer_date: last_step.end_at.to_date - 1.day
        )
      end

      it 'envia as etapas anteriores, mas não a última etapa (ainda aberta)' do
        subject.post_to_ieducar!

        expect(faltas_geral_request.with { |req| req.body.include?('etapa=1') }).to have_been_made.once
        expect(faltas_geral_request.with { |req| req.body.include?('etapa=2') }).not_to have_been_made
      end
    end

    context 'quando o aluno foi transferido após o encerramento da última etapa' do
      subject do
        described_class.new(
          student: student,
          classroom: classroom,
          transfer_date: last_step.end_at.to_date
        )
      end

      it 'envia todas as etapas, incluindo a última (já encerrada)' do
        subject.post_to_ieducar!

        expect(faltas_geral_request.with { |req| req.body.include?('etapa=1') }).to have_been_made.once
        expect(faltas_geral_request.with { |req| req.body.include?('etapa=2') }).to have_been_made.once
      end
    end

    context 'quando a data de transferência não é informada' do
      subject { described_class.new(student: student, classroom: classroom) }

      it 'mantém o comportamento atual e envia todas as etapas' do
        subject.post_to_ieducar!

        expect(faltas_geral_request.with { |req| req.body.include?('etapa=1') }).to have_been_made.once
        expect(faltas_geral_request.with { |req| req.body.include?('etapa=2') }).to have_been_made.once
      end
    end

    context 'quando a data de transferência chega como string ISO (fluxo real do worker)' do
      subject do
        described_class.new(
          student: student,
          classroom: classroom,
          transfer_date: (last_step.end_at.to_date - 1.day).iso8601
        )
      end

      it 'faz o parse da string e não envia a última etapa (ainda aberta)' do
        subject.post_to_ieducar!

        expect(faltas_geral_request.with { |req| req.body.include?('etapa=1') }).to have_been_made.once
        expect(faltas_geral_request.with { |req| req.body.include?('etapa=2') }).not_to have_been_made
      end
    end

    context 'quando a data de transferência é inválida' do
      subject do
        described_class.new(
          student: student,
          classroom: classroom,
          transfer_date: 'data-invalida'
        )
      end

      it 'notifica o Honeybadger e mantém o envio de todas as etapas (fallback)' do
        allow(Honeybadger).to receive(:notify)

        expect { subject.post_to_ieducar! }.not_to raise_error

        expect(Honeybadger).to have_received(:notify).once
        expect(faltas_geral_request.with { |req| req.body.include?('etapa=1') }).to have_been_made.once
        expect(faltas_geral_request.with { |req| req.body.include?('etapa=2') }).to have_been_made.once
      end
    end

    context 'quando a data de transferência é uma string vazia' do
      subject do
        described_class.new(student: student, classroom: classroom, transfer_date: '')
      end

      it 'trata como ausente e envia todas as etapas' do
        subject.post_to_ieducar!

        expect(faltas_geral_request.with { |req| req.body.include?('etapa=2') }).to have_been_made.once
      end
    end
  end

  describe '#post_to_ieducar! - turma avaliada com nota não é afetada pelo filtro' do
    let(:last_step) { classroom.calendar.classroom_steps.last }
    let(:faltas_geral_request) do
      a_request(
        :post,
        %r{http://test.ieducar.com.br/module/Api/Diario\?.*action=faltas-geral.*}
      )
    end

    before do
      stub_request(:post, %r{http://test.ieducar.com.br/module/Api/Diario})
        .to_return(
          status: 200,
          body: '{"msgs": [{"msg": "success", "type": "success"}], "any_error_msg": false}',
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    context 'quando o aluno foi transferido antes do encerramento da última etapa' do
      subject do
        described_class.new(
          student: student,
          classroom: classroom,
          transfer_date: last_step.end_at.to_date - 1.day
        )
      end

      it 'ignora o filtro e envia todas as etapas' do
        subject.post_to_ieducar!

        expect(faltas_geral_request.with { |req| req.body.include?('etapa=1') }).to have_been_made.once
        expect(faltas_geral_request.with { |req| req.body.include?('etapa=2') }).to have_been_made.once
      end
    end
  end

  describe '#post_to_ieducar!' do
    let(:first_step) { classroom.calendar.classroom_steps.first }

    before do
      stub_request(:post, %r{http://test.ieducar.com.br/module/Api/Diario})
        .to_return(
          status: 200,
          body: '{"msgs": [{"msg": "success", "type": "success"}], "any_error_msg": false}',
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    context 'when student is enrolled in classroom' do
      it 'does not raise error when successfully sending data' do
        expect { subject.post_to_ieducar! }.not_to raise_error
      end
    end

    context 'with numerical scores' do
      let!(:avaliation) do
        create(
          :avaliation,
          classroom: classroom,
          discipline: discipline,
          teacher_id: teacher.id,
          test_date: first_step.start_at + 5.days
        )
      end
      let!(:daily_note) { create(:daily_note, avaliation: avaliation) }
      let!(:daily_note_student) do
        create(
          :daily_note_student,
          student_id: student.id,
          daily_note: daily_note,
          note: 8.5
        )
      end

      it 'sends numerical scores to i-Educar' do
        exam_stub = stub_request(:post, %r{http://test.ieducar.com.br/module/Api/Diario\?.*action=notas.*})
          .to_return(
          status: 200,
          body: '{"msgs": [{"msg": "success", "type": "success"}], "any_error_msg": false}',
          headers: { 'Content-Type' => 'application/json' }
        )

        subject.post_to_ieducar!

        expect(exam_stub).to have_been_requested.at_least_once
      end

    end

    context 'with school term recovery scores' do
      let!(:avaliation) do
        create(
          :avaliation,
          classroom: classroom,
          discipline: discipline,
          teacher_id: teacher.id,
          test_date: first_step.start_at + 5.days
        )
      end
      let!(:daily_note) { create(:daily_note, avaliation: avaliation) }
      let!(:daily_note_student) do
        create(
          :daily_note_student,
          student_id: student.id,
          daily_note: daily_note,
          note: 5.0
        )
      end
      let!(:recovery_diary_record) do
        recovery_record = build(
          :recovery_diary_record,
          :with_teacher_discipline_classroom,
          unity: unity,
          classroom: classroom,
          discipline: discipline,
          teacher_id: teacher.id
        )
        recovery_record.students << build(:recovery_diary_record_student, student: student, score: 7.0, recovery_diary_record: recovery_record)
        recovery_record.save!

        create(
          :school_term_recovery_diary_record,
          step_id: first_step.id,
          step_number: first_step.to_number,
          recovery_diary_record: recovery_record
        )
      end

      it 'sends recovery scores to i-Educar' do
        exam_stub = stub_request(:post, %r{http://test.ieducar.com.br/module/Api/Diario\?.*action=notas.*})
          .to_return(
          status: 200,
          body: '{"msgs": [{"msg": "success", "type": "success"}], "any_error_msg": false}',
          headers: { 'Content-Type' => 'application/json' }
        )

        subject.post_to_ieducar!

        expect(exam_stub).to have_been_requested.at_least_once
      end
    end

    context 'with conceptual scores' do
      let!(:conceptual_exam) do
        exam = build(
          :conceptual_exam,
          :with_teacher_discipline_classroom,
          classroom: classroom,
          student: student,
          teacher_id: teacher.id,
          step_number: first_step.to_number
        )
        exam.step_id = first_step.id
        exam.conceptual_exam_values << build(:conceptual_exam_value, discipline: discipline, value: 'A', conceptual_exam: exam)
        exam.save!
        exam
      end

      before do
        classroom.first_exam_rule.update(score_type: ScoreTypes::CONCEPT)
        teacher_discipline_classroom.update(score_type: ScoreTypes::CONCEPT)
      end

      it 'sends conceptual scores to i-Educar' do
        exam_stub = stub_request(:post, %r{http://test.ieducar.com.br/module/Api/Diario\?.*action=notas.*})
          .to_return(
          status: 200,
          body: '{"msgs": [{"msg": "success", "type": "success"}], "any_error_msg": false}',
          headers: { 'Content-Type' => 'application/json' }
        )

        subject.post_to_ieducar!

        expect(exam_stub).to have_been_requested.at_least_once
      end
    end

    context 'with absences (general frequency)' do
      let!(:daily_frequency) do
        create(
          :daily_frequency,
          :without_discipline,
          classroom: classroom,
          teacher_id: teacher.id,
          frequency_date: first_step.start_at + 5.days
        )
      end
      let!(:daily_frequency_student) do
        create(
          :daily_frequency_student,
          daily_frequency: daily_frequency,
          student_id: student.id,
          present: false
        )
      end

      it 'sends absences to i-Educar' do
        absence_stub = stub_request(:post, %r{http://test.ieducar.com.br/module/Api/Diario\?.*action=faltas-geral.*})
          .to_return(
          status: 200,
          body: '{"msgs": [{"msg": "success", "type": "success"}], "any_error_msg": false}',
          headers: { 'Content-Type' => 'application/json' }
        )

        subject.post_to_ieducar!

        expect(absence_stub).to have_been_requested.at_least_once
      end

    end

    context 'with absences by discipline' do
      let!(:daily_frequency) do
        create(
          :daily_frequency,
          :with_teacher_discipline_classroom,
          classroom: classroom,
          discipline: discipline,
          teacher_id: teacher.id,
          frequency_date: first_step.start_at + 5.days
        )
      end
      let!(:daily_frequency_student) do
        create(
          :daily_frequency_student,
          daily_frequency: daily_frequency,
          student_id: student.id,
          present: false
        )
      end

      before do
        classroom.first_exam_rule.update(frequency_type: FrequencyTypes::BY_DISCIPLINE)
      end

      it 'sends absences grouped by discipline' do
        absence_stub = stub_request(:post, %r{http://test.ieducar.com.br/module/Api/Diario\?.*action=faltas-por-componente.*})
          .to_return(
          status: 200,
          body: '{"msgs": [{"msg": "success", "type": "success"}], "any_error_msg": false}',
          headers: { 'Content-Type' => 'application/json' }
        )

        subject.post_to_ieducar!

        expect(absence_stub).to have_been_requested.at_least_once
      end
    end

    context 'with descriptive exams' do
      let!(:descriptive_exam) do
        exam = create(
          :descriptive_exam,
          :with_teacher_discipline_classroom,
          classroom: classroom,
          discipline: discipline,
          teacher_id: teacher.id,
          opinion_type: OpinionTypes::BY_STEP_AND_DISCIPLINE,
          step_number: first_step.to_number
        )
        exam.step_id = first_step.id
        exam.save!
        exam
      end
      let!(:descriptive_exam_student) do
        create(
          :descriptive_exam_student,
          descriptive_exam: descriptive_exam,
          student: student,
          value: 'Aluno demonstrou excelente desempenho'
        )
      end

      before do
        classroom.first_exam_rule.update(opinion_type: OpinionTypes::BY_STEP_AND_DISCIPLINE)
      end

      it 'sends descriptive exams to i-Educar' do
        descriptive_stub = stub_request(:post, %r{http://test.ieducar.com.br/module/Api/Diario\?.*action=pareceres.*})
          .to_return(
          status: 200,
          body: '{"msgs": [{"msg": "success", "type": "success"}], "any_error_msg": false}',
          headers: { 'Content-Type' => 'application/json' }
        )

        subject.post_to_ieducar!

        expect(descriptive_stub).to have_been_requested.at_least_once
      end
    end

    context 'with student using differentiated exam rule' do
      before do
        student.update(uses_differentiated_exam_rule: true)
        differentiated_rule = create(
          :exam_rule,
          score_type: ScoreTypes::CONCEPT,
          opinion_type: OpinionTypes::BY_STEP_AND_DISCIPLINE
        )
        classroom.first_exam_rule.update(differentiated_exam_rule: differentiated_rule)
      end

      it 'uses differentiated exam rule for the student' do
        expect(subject.send(:exam_rule)).to eq(classroom.first_exam_rule.differentiated_exam_rule)
      end
    end

    describe '#all_postings_sent' do
      it 'starts as true before any posting is sent' do
        expect(described_class.new(student: student, classroom: classroom).all_postings_sent).to eq(true)
      end

      context 'when every i-Educar response is successful' do
        let!(:avaliation) do
          create(
            :avaliation,
            classroom: classroom,
            discipline: discipline,
            teacher_id: teacher.id,
            test_date: first_step.start_at + 5.days
          )
        end
        let!(:daily_note) { create(:daily_note, avaliation: avaliation) }
        let!(:daily_note_student) do
          create(
            :daily_note_student,
            student_id: student.id,
            daily_note: daily_note,
            note: 8.5
          )
        end

        it 'keeps all_postings_sent as true' do
          subject.post_to_ieducar!

          expect(subject.all_postings_sent).to eq(true)
        end
      end

      context 'when i-Educar returns a known error for at least one posting' do
        let!(:avaliation) do
          create(
            :avaliation,
            classroom: classroom,
            discipline: discipline,
            teacher_id: teacher.id,
            test_date: first_step.start_at + 5.days
          )
        end
        let!(:daily_note) { create(:daily_note, avaliation: avaliation) }
        let!(:daily_note_student) do
          create(
            :daily_note_student,
            student_id: student.id,
            daily_note: daily_note,
            note: 8.5
          )
        end
        let(:known_error_response) do
          {
            error: {
              code: IeducarErrorMessages::TEACHER_MUST_HAVE_SCORES_ON_PREVIOUS_STEPS,
              message: 'Nota somente pode ser lançada após lançar notas nas etapas: 1 Trimestre'
            },
            msgs: [{ msg: 'Nota somente pode ser lançada após lançar notas nas etapas: 1 Trimestre', type: 'error' }],
            any_error_msg: true
          }.to_json
        end

        before do
          stub_request(:post, %r{http://test.ieducar.com.br/module/Api/Diario\?.*action=notas.*})
            .to_return(
              status: 200,
              body: known_error_response,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'flips all_postings_sent to false' do
          subject.post_to_ieducar!

          expect(subject.all_postings_sent).to eq(false)
        end

        it 'does not raise an exception (known error stays silent on IeducarApi::Base)' do
          expect { subject.post_to_ieducar! }.not_to raise_error
        end
      end
    end
  end
end
