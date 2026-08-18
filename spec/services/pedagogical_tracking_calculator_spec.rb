# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PedagogicalTrackingCalculator, type: :service do
  let(:entity) { Entity.find_by_domain('test.host') }
  let(:year) { Date.current.year }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  let(:unity) { create(:unity) }
  # O ambiente de teste roda com a data congelada; usar o dia corrente mantém o
  # lançamento dentro da janela aceita pelas validações de data.
  let(:school_day) { Date.current }
  let!(:school_calendar) { create(:school_calendar, :with_one_step, unity: unity, year: year) }

  let(:params) do
    {
      search: {
        start_date: Date.new(year, 1, 1).to_s,
        end_date: Date.new(year, 12, 31).to_s
      }
    }
  end

  subject(:calculator) do
    described_class.new(
      entity: entity,
      year: year,
      current_user: nil,
      params: params,
      employee_unities: nil
    )
  end

  before do
    create(:unity_school_day, unity: unity, school_day: school_day)
  end

  describe '#calculate_index_data' do
    describe 'updated_at' do
      it 'shows the oldest refresh among the views' do
        create(
          :materialized_view_refresh,
          view_name: MvwFrequencyBySchoolClassroomTeacher.table_name,
          refreshed_at: Time.zone.local(year, 5, 10, 4, 30)
        )
        create(
          :materialized_view_refresh,
          view_name: MvwContentRecordBySchoolClassroomTeacher.table_name,
          refreshed_at: Time.zone.local(year, 5, 9, 3, 15)
        )

        data = calculator.calculate_index_data

        expect(data[:updated_at]).to eq(date: "09/05/#{year}", hour: 3)
      end

      it 'falls back to the only registered view' do
        create(
          :materialized_view_refresh,
          view_name: MvwContentRecordBySchoolClassroomTeacher.table_name,
          refreshed_at: Time.zone.local(year, 6, 20, 5, 15)
        )

        data = calculator.calculate_index_data

        expect(data[:updated_at]).to eq(date: "20/06/#{year}", hour: 5)
      end

      it 'is nil when no refresh was registered yet' do
        data = calculator.calculate_index_data

        expect(data[:updated_at]).to be_nil
      end
    end

    describe 'percentages' do
      # Um dia letivo na unidade e uma única turma: com frequência e conteúdo
      # registrados nesse dia, os dois percentuais têm que fechar em 100%.
      it 'reaches full percentage when the only school day has frequency and content' do
        teacher = create(:teacher)
        classroom = create(
          :classroom,
          :score_type_numeric,
          :with_classroom_semester_steps,
          unity: unity,
          year: year,
          school_calendar: school_calendar
        )
        discipline = create(:discipline)

        create(
          :teacher_discipline_classroom,
          teacher: teacher,
          classroom: classroom,
          discipline: discipline
        )
        create(
          :daily_frequency,
          classroom: classroom,
          discipline: discipline,
          teacher: teacher,
          frequency_date: school_day
        )

        content_record = create(
          :content_record,
          :with_contents,
          teacher: teacher,
          classroom: classroom,
          record_date: school_day
        )
        content_record.current_user = User.current
        create(
          :discipline_content_record,
          content_record: content_record,
          discipline: discipline,
          teacher_id: teacher.id
        )

        RefreshPedagogicalTrackingViewsWorker.new.tap { |worker|
          allow(worker).to receive(:populated?).and_return(false)
        }.perform(entity.id, [])

        data = calculator.calculate_index_data

        expect(data[:school_days]).to eq(1)
        expect(data[:school_frequency_done_percentage]).to eq(100.0)
        expect(data[:school_content_record_done_percentage]).to eq(100.0)
      end

      it 'is zero for a unity whose school day has no records' do
        create(
          :classroom,
          :score_type_numeric,
          :with_classroom_semester_steps,
          unity: unity,
          year: year,
          school_calendar: school_calendar
        )

        data = calculator.calculate_index_data

        expect(data[:school_days]).to eq(1)
        expect(data[:school_frequency_done_percentage]).to eq(0.0)
        expect(data[:school_content_record_done_percentage]).to eq(0.0)
      end
    end
  end
end
