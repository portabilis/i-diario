# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IeducarStudentTransferDataFetcher, type: :service do
  let(:entity) { Entity.find_by_domain('test.host') }
  # O serviço usa IeducarApiConfiguration.current — o primeiro registro do banco da entidade de
  # teste, que já vem semeado. Criar um segundo pela factory não o alcança, então configuramos ele.
  let!(:ieducar_api_configuration) do
    IeducarApiConfiguration.current.tap do |configuration|
      configuration.assign_attributes(attributes_for(:ieducar_api_configuration, :with_api_security_token))
      configuration.save!
    end
  end
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

  # Faltas e notas são enviadas pela API v2 do i-Educar, em endpoints e formato próprios. Ela
  # responde 201 quando grava.
  before do
    stub_request(:post, 'http://test.ieducar.com.br/api/v2/notas')
      .to_return(
        status: 201,
        body: '{"message": "Nota salva com sucesso."}',
        headers: { 'Content-Type' => 'application/json' }
      )
    stub_request(:post, 'http://test.ieducar.com.br/api/v2/falta-geral')
      .to_return(
        status: 201,
        body: '{"message": "Faltas gerais salvas com sucesso."}',
        headers: { 'Content-Type' => 'application/json' }
      )
    stub_request(:post, 'http://test.ieducar.com.br/api/v2/falta-componente')
      .to_return(
        status: 201,
        body: '{"message": "Falta por componente salva com sucesso."}',
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  subject { described_class.new(student: student, classroom: classroom) }

  # Regressão issue 7960: turmas sem nota (apuração apenas por frequência) só
  # devem ter a última etapa enviada quando ela já está encerrada na data da
  # transferência, evitando aprovar o aluno com uma etapa parcial.
  describe '#post_to_ieducar! - last step for classrooms without a score' do
    let(:last_step) { classroom.calendar.classroom_steps.last }
    let(:faltas_geral_request) do
      a_request(:post, 'http://test.ieducar.com.br/api/v2/falta-geral')
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

    context 'when the student was transferred before the last step closed' do
      subject do
        described_class.new(
          student: student,
          classroom: classroom,
          transfer_date: last_step.end_at.to_date - 1.day
        )
      end

      it 'sends the previous steps but not the last one (still open)' do
        subject.post_to_ieducar!

        expect(faltas_geral_request.with { |req| req.body.include?('"etapa":1') }).to have_been_made.once
        expect(faltas_geral_request.with { |req| req.body.include?('"etapa":2') }).not_to have_been_made
      end

      it 'sets last_step_skipped to true' do
        subject.post_to_ieducar!

        expect(subject.last_step_skipped).to eq(true)
      end
    end

    context 'when the student was transferred after the last step closed' do
      subject do
        described_class.new(
          student: student,
          classroom: classroom,
          transfer_date: last_step.end_at.to_date
        )
      end

      it 'sends all steps, including the last one (already closed)' do
        subject.post_to_ieducar!

        expect(faltas_geral_request.with { |req| req.body.include?('"etapa":1') }).to have_been_made.once
        expect(faltas_geral_request.with { |req| req.body.include?('"etapa":2') }).to have_been_made.once
      end

      it 'keeps last_step_skipped as false' do
        subject.post_to_ieducar!

        expect(subject.last_step_skipped).to eq(false)
      end
    end

    context 'when the transfer date is not provided' do
      subject { described_class.new(student: student, classroom: classroom) }

      it 'uses the current date and sends all steps when today is past the last step end' do
        Timecop.freeze(last_step.end_at.to_date + 1.day) do
          subject.post_to_ieducar!
        end

        expect(faltas_geral_request.with { |req| req.body.include?('"etapa":1') }).to have_been_made.once
        expect(faltas_geral_request.with { |req| req.body.include?('"etapa":2') }).to have_been_made.once
      end

      it 'uses the current date and skips the last step when today is still within it' do
        Timecop.freeze(last_step.start_at + 1.day) do
          subject.post_to_ieducar!
        end

        expect(faltas_geral_request.with { |req| req.body.include?('"etapa":1') }).to have_been_made.once
        expect(faltas_geral_request.with { |req| req.body.include?('"etapa":2') }).not_to have_been_made
        expect(subject.last_step_skipped).to eq(true)
      end
    end

    context 'when the transfer date arrives as an ISO string (real worker flow)' do
      subject do
        described_class.new(
          student: student,
          classroom: classroom,
          transfer_date: (last_step.end_at.to_date - 1.day).iso8601
        )
      end

      it 'parses the string and does not send the last step (still open)' do
        subject.post_to_ieducar!

        expect(faltas_geral_request.with { |req| req.body.include?('"etapa":1') }).to have_been_made.once
        expect(faltas_geral_request.with { |req| req.body.include?('"etapa":2') }).not_to have_been_made
      end
    end

    context 'when the transfer date is invalid' do
      subject do
        described_class.new(
          student: student,
          classroom: classroom,
          transfer_date: 'data-invalida'
        )
      end

      it 'notifies Honeybadger and falls back to the current date' do
        allow(Honeybadger).to receive(:notify)

        # Hoje após o fim da última etapa: fallback (data corrente) envia todas.
        Timecop.freeze(last_step.end_at.to_date + 1.day) do
          expect { subject.post_to_ieducar! }.not_to raise_error
        end

        expect(Honeybadger).to have_received(:notify).once
        expect(faltas_geral_request.with { |req| req.body.include?('"etapa":1') }).to have_been_made.once
        expect(faltas_geral_request.with { |req| req.body.include?('"etapa":2') }).to have_been_made.once
      end
    end

    context 'when the transfer date is an empty string' do
      subject do
        described_class.new(student: student, classroom: classroom, transfer_date: '')
      end

      it 'treats it as absent and uses the current date' do
        Timecop.freeze(last_step.end_at.to_date + 1.day) do
          subject.post_to_ieducar!
        end

        expect(faltas_geral_request.with { |req| req.body.include?('"etapa":2') }).to have_been_made.once
      end
    end
  end

  describe '#post_to_ieducar! - classrooms with a score are not affected by the filter' do
    let(:last_step) { classroom.calendar.classroom_steps.last }
    let(:faltas_geral_request) do
      a_request(:post, 'http://test.ieducar.com.br/api/v2/falta-geral')
    end

    before do
      stub_request(:post, %r{http://test.ieducar.com.br/module/Api/Diario})
        .to_return(
          status: 200,
          body: '{"msgs": [{"msg": "success", "type": "success"}], "any_error_msg": false}',
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    context 'when the student was transferred before the last step closed' do
      subject do
        described_class.new(
          student: student,
          classroom: classroom,
          transfer_date: last_step.end_at.to_date - 1.day
        )
      end

      it 'ignores the filter and sends all steps' do
        subject.post_to_ieducar!

        expect(faltas_geral_request.with { |req| req.body.include?('"etapa":1') }).to have_been_made.once
        expect(faltas_geral_request.with { |req| req.body.include?('"etapa":2') }).to have_been_made.once
        expect(subject.last_step_skipped).to eq(false)
      end
    end
  end

  # Regressão: etapa que ainda não começou não tem lançamento algum,
  # mas a contagem de faltas sobre um período vazio devolve 0 — sem guarda, esse
  # 0 chegava ao i-Educar como frequência zerada. Vale para qualquer regra de
  # avaliação, inclusive turmas avaliadas com nota.
  describe '#post_to_ieducar! - future steps are not sent' do
    let(:first_step) { classroom.calendar.classroom_steps.first }
    let(:last_step) { classroom.calendar.classroom_steps.last }
    let(:date_within_first_step) { first_step.start_at.to_date + 5.days }
    let(:diario_request) do
      a_request(:post, %r{http://test.ieducar.com.br/module/Api/Diario})
    end
    let(:faltas_geral_request) do
      a_request(:post, 'http://test.ieducar.com.br/api/v2/falta-geral')
    end

    before do
      stub_request(:post, %r{http://test.ieducar.com.br/module/Api/Diario})
        .to_return(
          status: 200,
          body: '{"msgs": [{"msg": "success", "type": "success"}], "any_error_msg": false}',
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    context 'when the classroom uses a score and the transfer happens before the last step starts' do
      subject do
        described_class.new(
          student: student,
          classroom: classroom,
          transfer_date: date_within_first_step
        )
      end

      it 'sends the ongoing step, even if partial' do
        subject.post_to_ieducar!

        expect(faltas_geral_request.with { |req| req.body.include?('"etapa":1') }).to have_been_made.once
      end

      it 'does not send any data from the future step, not even zeroed absences' do
        subject.post_to_ieducar!

        expect(diario_request.with { |req| req.body.include?('etapa=2') }).not_to have_been_made
        expect(faltas_geral_request.with { |req| req.body.include?('"etapa":2') }).not_to have_been_made
      end

      it 'sets last_step_skipped to true' do
        subject.post_to_ieducar!

        expect(subject.last_step_skipped).to eq(true)
      end
    end

    context 'when the classroom has no score and i-Educar does not provide the transfer date' do
      subject { described_class.new(student: student, classroom: classroom) }

      before do
        classroom.first_exam_rule.update(
          score_type: ScoreTypes::DONT_USE,
          frequency_type: FrequencyTypes::GENERAL
        )
      end

      it 'uses the current date and does not send the future step' do
        Timecop.freeze(date_within_first_step) do
          subject.post_to_ieducar!
        end

        expect(faltas_geral_request.with { |req| req.body.include?('"etapa":1') }).to have_been_made.once
        expect(diario_request.with { |req| req.body.include?('etapa=2') }).not_to have_been_made
        expect(faltas_geral_request.with { |req| req.body.include?('"etapa":2') }).not_to have_been_made
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
        exam_stub = stub_request(:post, 'http://test.ieducar.com.br/api/v2/notas')
          .with(
            headers: { 'token' => ieducar_api_configuration.api_security_token },
            body: hash_including(
              'turma_id' => classroom.api_code.to_i,
              'aluno_id' => student.api_code.to_i,
              'componente_id' => discipline.api_code.to_i,
              'etapa' => first_step.to_number,
              'nota' => 8.5
            )
          )
          .to_return(
            status: 201,
            body: '{"message": "Nota salva com sucesso."}',
            headers: { 'Content-Type' => 'application/json' }
          )

        subject.post_to_ieducar!

        expect(exam_stub).to have_been_requested.once
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
        exam_stub = stub_request(:post, 'http://test.ieducar.com.br/api/v2/notas')
          .with(
            headers: { 'token' => ieducar_api_configuration.api_security_token },
            body: hash_including(
              'turma_id' => classroom.api_code.to_i,
              'aluno_id' => student.api_code.to_i,
              'componente_id' => discipline.api_code.to_i,
              'etapa' => first_step.to_number,
              'nota' => 5.0,
              'recuperacao' => 7.0
            )
          )
          .to_return(
            status: 201,
            body: '{"message": "Nota salva com sucesso."}',
            headers: { 'Content-Type' => 'application/json' }
          )

        subject.post_to_ieducar!

        expect(exam_stub).to have_been_requested.once
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
        exam_stub = stub_request(:post, 'http://test.ieducar.com.br/api/v2/notas')
          .with(
            headers: { 'token' => ieducar_api_configuration.api_security_token },
            body: hash_including(
              'turma_id' => classroom.api_code.to_i,
              'aluno_id' => student.api_code.to_i,
              'componente_id' => discipline.api_code.to_i,
              'etapa' => first_step.to_number,
              'nota' => a_kind_of(Numeric)
            )
          )
          .to_return(
            status: 201,
            body: '{"message": "Nota salva com sucesso."}',
            headers: { 'Content-Type' => 'application/json' }
          )

        subject.post_to_ieducar!

        expect(exam_stub).to have_been_requested.once
      end
    end

    context 'with final recovery' do
      let(:last_step) { classroom.calendar.classroom_steps.last }

      # A recuperação final é registrada num dia letivo da última etapa e não pode ser futura: o
      # relógio avança para depois da etapa só neste exemplo.
      def create_final_recovery_diary_record
        recorded_at = (last_step.start_at..last_step.end_at).find do |date|
          date.on_weekday? && date > last_step.start_at + 5.days
        end
        recovery_record = build(
          :recovery_diary_record,
          :with_teacher_discipline_classroom,
          unity: unity,
          classroom: classroom,
          discipline: discipline,
          teacher_id: teacher.id,
          recorded_at: recorded_at
        )
        recovery_record.students << build(
          :recovery_diary_record_student, student: student, score: 6.0, recovery_diary_record: recovery_record
        )
        recovery_record.save!

        create(
          :final_recovery_diary_record,
          recovery_diary_record: recovery_record,
          school_calendar: classroom.calendar.school_calendar
        )
      end

      it 'sends the final recovery score to i-Educar on the Rc step' do
        final_recovery_stub = stub_request(:post, 'http://test.ieducar.com.br/api/v2/notas')
          .with(
            body: hash_including(
              'turma_id' => classroom.api_code.to_i,
              'aluno_id' => student.api_code.to_i,
              'componente_id' => discipline.api_code.to_i,
              'etapa' => 'Rc',
              'nota' => 6.0
            )
          )
          .to_return(
            status: 201,
            body: '{"message": "Nota salva com sucesso."}',
            headers: { 'Content-Type' => 'application/json' }
          )

        Timecop.travel(last_step.end_at + 1.day) do
          create_final_recovery_diary_record

          subject.post_to_ieducar!
        end

        expect(final_recovery_stub).to have_been_requested.once
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
        absence_stub = stub_request(:post, 'http://test.ieducar.com.br/api/v2/falta-geral')
          .with(
            headers: { 'token' => ieducar_api_configuration.api_security_token },
            body: hash_including(
              'turma_id' => classroom.api_code.to_i,
              'aluno_id' => student.api_code.to_i,
              'etapa' => first_step.to_number,
              'faltas' => 1
            )
          )
          .to_return(
          status: 201,
          body: '{"message": "Faltas gerais salvas com sucesso."}',
          headers: { 'Content-Type' => 'application/json' }
        )

        subject.post_to_ieducar!

        # Contagem exata: envio duplicado de falta geral é falha conhecida deste endpoint — a
        # violação de `falta_geral_pkey` está na lista de retry do Ieducar::SendPostWorker.
        expect(absence_stub).to have_been_requested.once
      end

      it 'flips all_postings_sent to false when the i-Educar refuses the absences' do
        stub_request(:post, 'http://test.ieducar.com.br/api/v2/falta-geral')
          .to_return(
            status: 422,
            body: '{"message": "A regra da turma 4502 não permite lançamento de faltas geral."}',
            headers: { 'Content-Type' => 'application/json' }
          )
        allow(Honeybadger).to receive(:notify)

        subject.post_to_ieducar!

        expect(subject.all_postings_sent).to eq(false)
      end

      # `post_to_ieducar!` não tem rescue: um erro de integração interrompe o laço e as etapas
      # seguintes não são enviadas. Quem repete é o IeducarStudentTransferPostingWorker.
      it 'lets an integration error abort the posting loop' do
        stub_request(:post, 'http://test.ieducar.com.br/api/v2/falta-geral')
          .to_return(
            status: 401,
            body: '{"message": "Unauthorized"}',
            headers: { 'Content-Type' => 'application/json' }
          )
        allow(Honeybadger).to receive(:notify)

        expect {
          subject.post_to_ieducar!
        }.to raise_error(
          IeducarApi::Base::GenericError,
          'Token de segurança divergente entre o i-Diário e o i-Educar.'
        )
      end

      # Aluno que deixou de frequentar não é falha da transferência: o i-Educar recusa porque não
      # há onde lançar, e isso não deve marcar o envio como parcial.
      it 'keeps all_postings_sent as true when there was no eligible registration' do
        stub_request(:post, 'http://test.ieducar.com.br/api/v2/falta-geral')
          .to_return(
            status: 422,
            body: {
              message: 'Matrícula não encontrada para o aluno e turma informados.',
              errors: { aluno_id: ['Matrícula não encontrada para o aluno e turma informados.'] }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        subject.post_to_ieducar!

        expect(subject.all_postings_sent).to eq(true)
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

      it 'sends absences by discipline to i-Educar' do
        absence_stub = stub_request(:post, 'http://test.ieducar.com.br/api/v2/falta-componente')
          .with(
            headers: { 'token' => ieducar_api_configuration.api_security_token },
            body: hash_including(
              'turma_id' => classroom.api_code.to_i,
              'aluno_id' => student.api_code.to_i,
              'componente_id' => discipline.api_code.to_i,
              'etapa' => first_step.to_number,
              'faltas' => 1
            )
          )
          .to_return(
            status: 201,
            body: '{"message": "Falta por componente salva com sucesso."}',
            headers: { 'Content-Type' => 'application/json' }
          )

        subject.post_to_ieducar!

        expect(absence_stub).to have_been_requested.once
      end

      it 'sends each discipline once even when it has more than one teacher in the classroom' do
        create(
          :teacher_discipline_classroom,
          classroom: classroom,
          discipline: discipline,
          score_type: ScoreTypes::NUMERIC
        )

        subject.post_to_ieducar!

        expect(a_request(:post, 'http://test.ieducar.com.br/api/v2/falta-componente')).to have_been_made.once
      end

      it 'flips all_postings_sent to false when the i-Educar refuses the absences' do
        stub_request(:post, 'http://test.ieducar.com.br/api/v2/falta-componente')
          .to_return(
            status: 422,
            body: { message: "Componente curricular de código #{discipline.api_code} não existe na turma." }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
        allow(Rails.logger).to receive(:warn)

        subject.post_to_ieducar!

        expect(subject.all_postings_sent).to eq(false)
        expect(Rails.logger).to have_received(:warn)
          .with(/\[transferência\] falta por componente \(componente: #{discipline.api_code}\) não enviada/)
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

      context 'when i-Educar refuses at least one posting' do
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
        before do
          stub_request(:post, 'http://test.ieducar.com.br/api/v2/notas')
            .to_return(
              status: 422,
              body: { message: 'Nota somente pode ser lançada após lançar notas nas etapas: 1 Trimestre' }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'flips all_postings_sent to false' do
          subject.post_to_ieducar!

          expect(subject.all_postings_sent).to eq(false)
        end

        it 'does not raise an exception, so the other postings are still sent' do
          expect { subject.post_to_ieducar! }.not_to raise_error
        end
      end
    end
  end
end
