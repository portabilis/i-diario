require 'rails_helper'

RSpec.describe Api::InfrequencyTrackingsService do
  let(:year) { 2026 }
  let(:unity) { create(:unity, api_code: 'unity-1') }
  let(:classroom) { create(:classroom, unity: unity, year: year) }
  let!(:classrooms_grade) { create(:classrooms_grade, classroom: classroom) }
  let(:start_at) { Date.new(2026, 6, 1) }
  let(:end_at) { Date.new(2026, 6, 30) }

  let(:other_unity) { create(:unity, api_code: 'unity-2') }
  let(:unities) { [unity] }

  subject(:result) { described_class.call(unities: unities, start_at: start_at, end_at: end_at) }

  def enroll(student, api_code:, joined_at:, left_at: '')
    student_enrollment = create(:student_enrollment, student: student, api_code: api_code)

    create(
      :student_enrollment_classroom,
      student_enrollment: student_enrollment,
      classrooms_grade: classrooms_grade,
      joined_at: joined_at,
      left_at: left_at
    )
  end

  def track(student, notification_date:, classroom: self.classroom, **attributes)
    create(
      :infrequency_tracking,
      { student: student, classroom: classroom, notification_date: notification_date }.merge(attributes)
    )
  end

  def row_of(student_api_code)
    result.find { |item| item[:student_api_code] == student_api_code }
  end

  it 'exposes the api_codes and the absence dates behind each notification' do
    student = create(:student, api_code: '777')
    enroll(student, api_code: '999', joined_at: '2026-02-01')

    track(
      student,
      notification_date: '2026-06-10',
      notification_type: InfrequencyTrackingTypes::CONSECUTIVE_ABSENCES,
      notification_data: [{ teacher_id: 1, absences: %w[2026-06-03 2026-06-01 2026-06-02] }]
    )

    expect(result).to eq(
      [
        {
          student_api_code: '777',
          registration_api_code: '999',
          classroom_api_code: classroom.api_code,
          unity_api_code: 'unity-1',
          notification_type: 'consecutive_absences',
          notification_date: '2026-06-10',
          # Ordenadas: quem consome agrupa as datas em episódios de afastamento.
          absence_dates: %w[2026-06-01 2026-06-02 2026-06-03],
          absences_count: 3
        }
      ]
    )
  end

  it 'lists the most recent notifications first' do
    student = create(:student, api_code: '777')

    track(student, notification_date: '2026-06-05')
    track(student, notification_date: '2026-06-25')
    track(student, notification_date: '2026-06-15')

    expect(result.map { |item| item[:notification_date] }).to eq(%w[2026-06-25 2026-06-15 2026-06-05])
  end

  # Quem saiu da turma e voltou tem duas matrículas nela: a que vale é a
  # vigente na data da notificação.
  it 'picks the enrollment in force on the notification date' do
    student = create(:student, api_code: '777')
    enroll(student, api_code: 'old', joined_at: '2026-02-01', left_at: '2026-04-01')
    enroll(student, api_code: 'current', joined_at: '2026-05-01')

    track(student, notification_date: '2026-06-10')

    expect(row_of('777')[:registration_api_code]).to eq('current')
  end

  it 'falls back to the latest enrollment when none is in force on the notification date' do
    student = create(:student, api_code: '777')
    enroll(student, api_code: 'first', joined_at: '2026-02-01', left_at: '2026-03-01')
    enroll(student, api_code: 'latest', joined_at: '2026-04-01', left_at: '2026-05-01')

    track(student, notification_date: '2026-06-10')

    expect(row_of('777')[:registration_api_code]).to eq('latest')
  end

  it 'returns a null registration when the student has no enrollment in the classroom' do
    student = create(:student, api_code: '777')

    track(student, notification_date: '2026-06-10')

    expect(row_of('777')[:registration_api_code]).to be_nil
  end

  # A notificação de um aluno depois unificado continua na tela do i-Diário;
  # aqui ela continua com o api_code dele, não com um nulo.
  it 'keeps the api_code of a discarded student' do
    student = create(:student, api_code: 'merged')
    track(student, notification_date: '2026-06-10')
    student.update_column(:discarded_at, Time.current)

    expect(row_of('merged')).to be_present
  end

  it 'keeps only the notifications inside the period' do
    track(create(:student, api_code: 'before'), notification_date: '2026-05-20')
    track(create(:student, api_code: 'inside'), notification_date: '2026-06-15')

    expect(result.map { |item| item[:student_api_code] }).to eq(['inside'])
  end

  it 'keeps only the notifications of the requested unity' do
    other_classroom = create(:classroom, unity: other_unity, year: year)

    track(create(:student, api_code: 'mine'), notification_date: '2026-06-15')
    track(create(:student, api_code: 'theirs'), notification_date: '2026-06-15', classroom: other_classroom)

    expect(result.map { |item| item[:student_api_code] }).to eq(['mine'])
  end

  context 'with more than one unity' do
    let(:unities) { [unity, other_unity] }

    it 'returns the notifications of every requested unity, each with its own api_code' do
      other_classroom = create(:classroom, unity: other_unity, year: year)

      track(create(:student, api_code: 'mine'), notification_date: '2026-06-15')
      track(create(:student, api_code: 'theirs'), notification_date: '2026-06-15', classroom: other_classroom)

      expect(result.map { |item| [item[:student_api_code], item[:unity_api_code]] })
        .to match_array([%w[mine unity-1], %w[theirs unity-2]])
    end
  end
end
