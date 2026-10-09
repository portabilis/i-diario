require 'rails_helper'

RSpec.describe DailyFrequenciesCreator, type: :service do
  let(:discipline) { create(:discipline) }
  let(:classroom) {
    create(
      :classroom,
      :with_classroom_semester_steps,
      :with_student_enrollment_classroom
    )
  }
  let(:default_class_numbers) { ['1'] }
  let(:two_class_numbers) { ['1', '2'] }
  let(:period) { Periods::MATUTINAL }
  let(:frequency_start_at) { Date.parse("#{school_calendar.year}-01-01") }
  let(:student_enrollment_classroom) { classroom.student_enrollment_classrooms.first }
  let(:student_enrollment) { student_enrollment_classroom.student_enrollment }
  let(:school_calendar) { classroom.calendar.school_calendar }

  it 'allows to create frequencies to current date when frequency_date argument is null' do
    student_enrollment_classroom.update_attribute(:joined_at, frequency_start_at)

    creator = described_class.new(
      unity_id: classroom.unity.id,
      classroom_id: classroom.id,
      school_calendar: school_calendar,
      period: period
    )

    expect { creator.find_or_create! }.to change { DailyFrequency.count }.to(1)
  end

  it 'does not create frequencies when frequency_date argument is not a valid one' do
    student_enrollment_classroom.update_attribute(:joined_at, frequency_start_at - 1.day)

    creator = described_class.new(
      unity_id: classroom.unity.id,
      classroom_id: classroom.id,
      school_calendar: school_calendar,
      frequency_date: frequency_start_at - 1.day,
      period: period
    )

    expect { creator.find_or_create! }.to_not(change { DailyFrequency.count })
  end

  it 'allows to create frequencies custom class numbers in the params' do
    student_enrollment_classroom.update_attribute(:joined_at, frequency_start_at)

    creator = described_class.new(
      unity_id: classroom.unity.id,
      classroom_id: classroom.id,
      school_calendar: school_calendar,
      class_numbers: default_class_numbers,
      discipline_id: discipline.id,
      period: period
    )

    creator.find_or_create!

    daily_frequency = DailyFrequency.last

    expect(daily_frequency.class_number).to eq 1
  end

  it 'allows to create frequencies with two custom class numbers in the params' do
    student_enrollment_classroom.update_attribute(:joined_at, frequency_start_at)

    creator = described_class.new(
      unity_id: classroom.unity.id,
      classroom_id: classroom.id,
      school_calendar: school_calendar,
      class_numbers: two_class_numbers,
      discipline_id: discipline.id,
      period: period
    )

    expect { creator.find_or_create! }.to change { DailyFrequency.count }.to(2)
  end

  it 'should create daily_frequency_students for available student_enrollment_classrooms' do
    student_enrollment_classroom.update_attribute(:joined_at, frequency_start_at)

    creator = described_class.new(
      unity_id: classroom.unity.id,
      classroom_id: classroom.id,
      school_calendar: school_calendar,
      class_numbers: default_class_numbers,
      discipline_id: discipline.id,
      period: period
    )

    creator.find_or_create!

    daily_frequency = creator.daily_frequencies[0]
    daily_frequency_student_exists = daily_frequency.students.where(
      student_id: student_enrollment.student_id
    ).exists?

    expect(daily_frequency_student_exists).to be true
  end

  it 'should not create daily_frequency_students for students exempted from discipline' do
    student_enrollment_classroom.update_attribute(:joined_at, frequency_start_at)

    StudentEnrollmentExemptedDiscipline.create!(
      student_enrollment: student_enrollment,
      discipline: discipline,
      steps: Array.new(classroom.calendar.classroom_steps.count) { |i| (i + 1).to_s }.join(',')
    )

    creator = described_class.new(
      unity_id: classroom.unity.id,
      classroom_id: classroom.id,
      school_calendar: school_calendar,
      class_numbers: default_class_numbers,
      discipline_id: discipline.id,
      period: period
    )

    creator.find_or_create!

    daily_frequency = creator.daily_frequencies[0]
    daily_frequency_student_exists = daily_frequency.students.where(
      student_id: student_enrollment.student_id
    ).exists?

    expect(daily_frequency_student_exists).to be false
  end

  describe 'with two class numbers' do
    let(:params) do
      {
        unity_id: classroom.unity.id,
        classroom_id: classroom.id,
        school_calendar: school_calendar,
        discipline_id: discipline.id,
        period: period
      }
    end

    it 'fills the students of the second class even when the first one already has them' do
      student_enrollment_classroom.update_attribute(:joined_at, frequency_start_at)
      described_class.find_or_create!(params.merge(class_numbers: ['1']))

      described_class.find_or_create!(params.merge(class_numbers: ['1', '2']))

      second_class = DailyFrequency.find_by(class_number: 2)
      expect(second_class.students.pluck(:student_id)).to eq([student_enrollment.student_id])
      expect(DailyFrequency.find_by(class_number: 1).students.count).to eq(1)
    end
  end

  describe 'lock key' do
    let(:key_for) do
      lambda { |attributes|
        creator = described_class.new(unity_id: classroom.unity.id, classroom_id: classroom.id)
        creator.send(:daily_frequency_lock_key, attributes)
      }
    end

    # O controller da API monta os valores a partir de params (texto) e o worker a partir do próprio
    # diário (Date e inteiro): sem o cast os dois tomariam locks diferentes para o mesmo diário.
    it 'is the same whether the values arrive as text or already typed' do
      as_text = key_for.call(
        classroom_id: '7', frequency_date: '2026-03-09', period: '1', discipline_id: '3', class_number: '2'
      )
      as_typed = key_for.call(
        classroom_id: 7, frequency_date: Date.new(2026, 3, 9), period: 1, discipline_id: 3, class_number: 2
      )

      expect(as_text).to eq(as_typed)
    end

    it 'differs for diaries that must not serialize against each other' do
      base = { classroom_id: 7, frequency_date: Date.new(2026, 3, 9), period: 1, discipline_id: 3, class_number: 2 }

      keys = [
        key_for.call(base),
        key_for.call(base.merge(classroom_id: 8)),
        key_for.call(base.merge(class_number: 3)),
        key_for.call(base.merge(period: 2))
      ]

      expect(keys.uniq.size).to eq(4)
    end
  end

  describe 'concurrent requests for the same new daily frequency', concurrent: true do
    let(:students_count) { 4 }
    # User.current é Thread.current[:user] e cada thread do Puma seta o seu; sem isso as threads do
    # spec rodam com um estado que a requisição real nunca tem.
    let(:current_user) { User.current }
    let(:params) do
      {
        unity_id: classroom.unity.id,
        classroom_id: classroom.id,
        school_calendar: school_calendar,
        discipline_id: discipline.id,
        period: period
      }
    end

    before do
      student_enrollment_classroom.update_attribute(:joined_at, frequency_start_at)
      (students_count - 1).times do
        create(:student_enrollment_classroom, classrooms_grade: classroom.classrooms_grades.first,
                                              joined_at: frequency_start_at)
      end
    end

    it 'creates the diary once and each student once, without any failed insert' do
      # aquece o autoloader clássico (não é thread-safe) numa aula que não entra na disputa
      described_class.find_or_create!(params.merge(class_numbers: ['9']))

      # Alarga a janela entre ler quem já tem registro e inserir, para toda thread que não estiver
      # serializada pelo lock enxergar o diário vazio e disputar os mesmos INSERTs. Se esta chamada
      # sair de onde está, o spec continua verde mas deixa de exercer a disputa.
      allow(AbsenceJustifiedOnDate).to receive(:call).and_wrap_original do |original, *args|
        sleep(0.3)
        original.call(*args)
      end

      insert_attempts = 0
      counter_lock = Mutex.new
      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
        sql = args.last[:sql]
        next unless sql.start_with?('INSERT INTO "daily_frequencies"', 'INSERT INTO "daily_frequency_students"')

        counter_lock.synchronize { insert_attempts += 1 }
      end

      begin
        start_at = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 0.2
        threads = Array.new(3) do
          Thread.new do
            ActiveRecord::Base.connection_pool.with_connection do
              User.current = current_user
              sleep(0.01) while Process.clock_gettime(Process::CLOCK_MONOTONIC) < start_at
              described_class.find_or_create!(params.merge(class_numbers: ['1']))
            end
          end
        end
        # sem teto, uma regressão no lock penduraria a suíte inteira em vez de falhar
        Timeout.timeout(30) { threads.each(&:join) }
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      daily_frequencies = DailyFrequency.where(class_number: 1)
      expect(daily_frequencies.count).to eq(1)
      expect(daily_frequencies.first.students.count).to eq(students_count)
      expect(insert_attempts).to eq(1 + students_count)
    end
  end
end
