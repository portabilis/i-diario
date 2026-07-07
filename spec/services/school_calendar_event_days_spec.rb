require 'spec_helper'

RSpec.describe SchoolCalendarEventDays, type: :service do
  let!(:school_calendars) {
    create_list(
      :school_calendar,
      2,
      :with_trimester_steps
    )
  }
  let(:list_classrooms) { create_list(:classroom, 3, unity: school_calendars.first.unity, period: Periods::MATUTINAL) }
  let(:list_classroom_grades) {
    list_classrooms.map do |classroom|
      create(
        :classrooms_grade,
        classroom: classroom,
      )
    end
  }
  let!(:classroom_grades_with_grade) {
    create(
      :classrooms_grade,
      classroom: list_classrooms.second,
      grade: list_classroom_grades.last.grade
    )
  }

  describe 'when to delete daily_frequencies' do
    context 'with coverage "by_grade" and event_type "extra_school_event_without_frequency"' do
      let!(:school_calendar_event) {
        build(
          :school_calendar_event,
          school_calendar: school_calendars.first,
          coverage: 'by_grade',
          periods: Periods::MATUTINAL,
          event_type: EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY,
          grade_id: list_classroom_grades.first.grade_id,
          course_id: list_classroom_grades.first.grade.course_id,
          classroom_id: '',
          show_in_frequency_record: false,
          start_date: '2017-02-10',
          end_date: '2017-02-16'
        )
      }
      let!(:daily_frequency) {
        create(
          :daily_frequency,
          classroom: list_classrooms.first,
          frequency_date: '2017-02-15',
          unity: list_classrooms.first.unity,
          school_calendar: school_calendars.first,
          period: Periods::MATUTINAL
        )
      }

      subject do
        SchoolCalendarEventDays.update_school_days(
          [school_calendars.first],
          [school_calendar_event],
          'create',
          '2017-02-10',
          '2017-02-16'
        )
      end

      it 'delete only the daily_frequency in the grade' do
        expect { subject }.to change { DailyFrequency.where(id: daily_frequency.id).count }.by(-1)
      end
    end

    context 'with coverage "by_unity" and event_type "extra_school_event_without_frequency"' do
      let(:list_classrooms_for_unity) { create_list(:classroom, 3, unity: school_calendars.last.unity, period: Periods::MATUTINAL) }
      let(:classroom_grades) {
        list_classrooms_for_unity.map do |classroom|
          create(
            :classrooms_grade,
            classroom: classroom,
          )
        end
      }
      let!(:school_calendar_event) {
        build(
          :school_calendar_event,
          school_calendar: school_calendars.last,
          coverage: 'by_unity',
          periods: Periods::MATUTINAL,
          event_type: EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY,
          grade_id: '',
          course_id: '',
          classroom_id: '',
          show_in_frequency_record: false,
          start_date: '2017-02-10',
          end_date: '2017-02-16'
        )
      }

      let!(:daily_frequency) {
        create(
          :daily_frequency,
          id: 456,
          classroom: list_classrooms_for_unity.first,
          frequency_date: '2017-02-15',
          unity: school_calendars.last.unity,
          school_calendar: school_calendars.last,
          period: Periods::MATUTINAL
        )
      }

      subject do
        SchoolCalendarEventDays.update_school_days(
          [school_calendars.last],
          [school_calendar_event],
          'create',
          '2017-02-10',
          '2017-02-16'
        )
      end

      it 'delete only the daily_frequency in the unity' do
        expect { subject }.to change { DailyFrequency.where(id: daily_frequency.id).count }.by(-1)
      end
    end

    context 'with coverage "by_classroom" and event_type "extra_school_event_without_frequency"' do
      let!(:school_calendar_event) {
        build(
          :school_calendar_event,
          school_calendar: school_calendars.first,
          coverage: 'by_classroom',
          periods: Periods::MATUTINAL,
          event_type: EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY,
          grade_id: list_classroom_grades.last.grade_id,
          course_id: list_classroom_grades.last.grade.course_id,
          classroom_id: list_classrooms.second.id,
          show_in_frequency_record: false,
          start_date: '2017-02-10',
          end_date: '2017-02-16'
        )
      }
      let!(:daily_frequency) {
        create(
          :daily_frequency,
          classroom: list_classrooms.second,
          frequency_date: '2017-02-15',
          unity: list_classrooms.second.unity,
          school_calendar: school_calendars.first,
          period: Periods::MATUTINAL
        )
      }

      subject do
        SchoolCalendarEventDays.update_school_days(
          [school_calendars.first],
          [school_calendar_event],
          'create',
          '2017-02-10',
          '2017-02-16'
        )
      end

      it 'delete only the daily_frequency in the classroom' do
        expect { subject }.to change { DailyFrequency.where(id: daily_frequency.id).count }.by(-1)
      end
    end

    context 'with coverage "by_course" and event_type "extra_school_event_without_frequency"' do
      let!(:grade_with_course) {
        create(
          :grade,
          course: list_classroom_grades.last.grade.course
        )
      }
      let!(:school_calendar_event) {
        build(
          :school_calendar_event,
          school_calendar: school_calendars.first,
          coverage: 'by_course',
          periods: Periods::MATUTINAL,
          event_type: EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY,
          grade_id: '',
          course_id: grade_with_course.course_id,
          classroom_id: '',
          show_in_frequency_record: false,
          start_date: '2017-02-10',
          end_date: '2017-02-16'
        )
      }
      let!(:daily_frequency) {
        create(
          :daily_frequency,
          classroom: list_classroom_grades.last.classroom,
          frequency_date: '2017-02-15',
          unity: list_classroom_grades.last.classroom.unity,
          school_calendar: school_calendars.first,
          period: Periods::MATUTINAL
        )
      }

      subject do
        SchoolCalendarEventDays.update_school_days(
          [school_calendars.first],
          [school_calendar_event],
          'create',
          '2017-02-10',
          '2017-02-16'
        )
      end

      it 'delete only the daily_frequency in the course' do
        expect { subject }.to change { DailyFrequency.where(id: daily_frequency.id).count }.by(-1)
      end
    end
  end

  describe 'when the event_type_changed parameter is true' do
    let!(:list_classrooms_for_unity) { create_list(:classroom, 3, unity: school_calendars.last.unity, period: Periods::MATUTINAL) }
    let!(:classroom_grades) {
      list_classrooms_for_unity.map do |classroom|
        create(
          :classrooms_grade,
          classroom: classroom,
        )
      end
    }
    let!(:daily_frequency) {
      create(
        :daily_frequency,
        id: 456,
        classroom: list_classrooms_for_unity.first,
        frequency_date: '2017-02-15',
        unity: school_calendars.last.unity,
        school_calendar: school_calendars.last,
        period: Periods::MATUTINAL
      )
    }
    let!(:unity_school_day) {
      create(
        :unity_school_day,
        unity: school_calendars.last.unity,
        school_day: '2017-02-15'
      )
    }

    subject do
      SchoolCalendarEventDays.update_school_days(
        [school_calendars.last],
        [school_calendar_event],
        'create',
        '2017-02-10',
        '2017-02-16',
        event_type_changed: true
      )
    end

    context 'when the event is EventTypes::NO_SCHOOL' do
      let!(:school_calendar_event) {
        build(
          :school_calendar_event,
          school_calendar: school_calendars.last,
          coverage: 'by_unity',
          periods: Periods::MATUTINAL,
          event_type: EventTypes::NO_SCHOOL,
          grade_id: '',
          course_id: '',
          classroom_id: '',
          show_in_frequency_record: false,
          start_date: '2017-02-10',
          end_date: '2017-02-16'
        )
      }

      it 'deletes the attendance and unity_school_day' do
        expect {
          subject
        }.to change { DailyFrequency.where(id: daily_frequency.id).count }.by(-1)
         .and change { UnitySchoolDay.where(id: unity_school_day.id).count }.by(-1)
      end
    end

    context 'when the event is EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY' do
      let!(:school_calendar_event) {
        build(
          :school_calendar_event,
          school_calendar: school_calendars.last,
          coverage: 'by_unity',
          periods: Periods::MATUTINAL,
          event_type: EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY,
          grade_id: '',
          course_id: '',
          classroom_id: '',
          show_in_frequency_record: false,
          start_date: '2017-02-10',
          end_date: '2017-02-16'
        )
      }

      it 'deletes only the attendance and not the unity_school_day' do
        expect {
          subject
        }.to change { DailyFrequency.where(id: daily_frequency.id).count }.by(-1)
        .and change {
          UnitySchoolDay.where(unity_id: school_calendars.last.unity, school_day: '2017-02-15').count
        }.by(0)
      end
    end

    context 'when the event is edited to NO_SCHOOL' do
      let!(:school_calendar_event) {
        build(
          :school_calendar_event,
          school_calendar: school_calendars.last,
          coverage: 'by_unity',
          periods: Periods::MATUTINAL,
          event_type: EventTypes::NO_SCHOOL,
          grade_id: '',
          course_id: '',
          classroom_id: '',
          show_in_frequency_record: false,
          start_date: '2017-02-10',
          end_date: '2017-02-16'
        )
      }
      let!(:daily_frequency) {
        create(
          :daily_frequency,
          classroom: list_classrooms_for_unity.first,
          frequency_date: '2017-02-15',
          unity: school_calendars.last.unity,
          school_calendar: school_calendars.last,
          period: Periods::MATUTINAL
        )
      }
      let!(:unity_school_day) {
        create(
          :unity_school_day,
          unity: school_calendars.last.unity,
          school_day: '2017-02-15'
        )
      }

      subject do
        SchoolCalendarEventDays.update_school_days(
          [school_calendars.last],
          [school_calendar_event],
          'update',
          '2017-02-10',
          '2017-02-16',
          event_type_changed: true
        )
      end

      it 'deletes the attendance and unity_school_day when changing to NO_SCHOOL' do
        expect {
          subject
        }.to change { DailyFrequency.where(id: daily_frequency.id).count }.by(-1)
         .and change { UnitySchoolDay.where(id: unity_school_day.id).count }.by(-1)
      end
    end
  end

  describe 'when creating NO_SCHOOL event with existing event on same date' do
    let!(:list_classrooms_for_unity) { create_list(:classroom, 3, unity: school_calendars.last.unity, period: Periods::MATUTINAL) }
    let!(:classroom_grades) {
      list_classrooms_for_unity.map do |classroom|
        create(:classrooms_grade, classroom: classroom)
      end
    }

    context 'when by_classroom event already exists and creating by_unity NO_SCHOOL event' do
      let!(:existing_event) {
        create(
          :school_calendar_event,
          school_calendar: school_calendars.last,
          coverage: 'by_classroom',
          periods: Periods::MATUTINAL,
          event_type: EventTypes::NO_SCHOOL,
          grade_id: classroom_grades.first.grade_id,
          course_id: classroom_grades.first.grade.course_id,
          classroom_id: list_classrooms_for_unity.first.id,
          show_in_frequency_record: false,
          start_date: '2017-02-15',
          end_date: '2017-02-15'
        )
      }
      let!(:new_event) {
        build(
          :school_calendar_event,
          school_calendar: school_calendars.last,
          coverage: 'by_unity',
          periods: Periods::MATUTINAL,
          event_type: EventTypes::NO_SCHOOL,
          grade_id: '',
          course_id: '',
          classroom_id: '',
          show_in_frequency_record: false,
          start_date: '2017-02-15',
          end_date: '2017-02-15'
        )
      }
      let!(:daily_frequency) {
        create(
          :daily_frequency,
          classroom: list_classrooms_for_unity.second,
          frequency_date: '2017-02-15',
          unity: school_calendars.last.unity,
          school_calendar: school_calendars.last,
          period: Periods::MATUTINAL
        )
      }

      subject do
        SchoolCalendarEventDays.update_school_days(
          [school_calendars.last],
          [new_event],
          'create',
          '2017-02-15',
          '2017-02-15'
        )
      end

      it 'deletes daily_frequency even when another event exists on the same date' do
        expect { subject }.to change { DailyFrequency.where(id: daily_frequency.id).count }.by(-1)
      end
    end

    context 'when by_grade event already exists and creating by_unity NO_SCHOOL event' do
      let!(:existing_event) {
        create(
          :school_calendar_event,
          school_calendar: school_calendars.last,
          coverage: 'by_grade',
          periods: Periods::MATUTINAL,
          event_type: EventTypes::NO_SCHOOL,
          grade_id: classroom_grades.first.grade_id,
          course_id: classroom_grades.first.grade.course_id,
          classroom_id: '',
          show_in_frequency_record: false,
          start_date: '2017-02-15',
          end_date: '2017-02-15'
        )
      }
      let!(:new_event) {
        build(
          :school_calendar_event,
          school_calendar: school_calendars.last,
          coverage: 'by_unity',
          periods: Periods::MATUTINAL,
          event_type: EventTypes::NO_SCHOOL,
          grade_id: '',
          course_id: '',
          classroom_id: '',
          show_in_frequency_record: false,
          start_date: '2017-02-15',
          end_date: '2017-02-15'
        )
      }
      let!(:daily_frequency) {
        create(
          :daily_frequency,
          classroom: list_classrooms_for_unity.second,
          frequency_date: '2017-02-15',
          unity: school_calendars.last.unity,
          school_calendar: school_calendars.last,
          period: Periods::MATUTINAL
        )
      }

      subject do
        SchoolCalendarEventDays.update_school_days(
          [school_calendars.last],
          [new_event],
          'create',
          '2017-02-15',
          '2017-02-15'
        )
      end

      it 'deletes daily_frequency even when another event exists on the same date' do
        expect { subject }.to change { DailyFrequency.where(id: daily_frequency.id).count }.by(-1)
      end
    end
  end

  describe 'when creating NO_SCHOOL event with specific period' do
    let!(:matutinal_classroom) {
      create(:classroom, unity: school_calendars.last.unity, period: Periods::MATUTINAL)
    }
    let!(:vespertine_classroom) {
      create(:classroom, unity: school_calendars.last.unity, period: Periods::VESPERTINE)
    }
    let!(:matutinal_classroom_grade) {
      create(:classrooms_grade, classroom: matutinal_classroom)
    }
    let!(:vespertine_classroom_grade) {
      create(:classrooms_grade, classroom: vespertine_classroom)
    }

    context 'when by_unity event has specific period defined' do
      let!(:matutinal_frequency) {
        create(
          :daily_frequency,
          classroom: matutinal_classroom,
          frequency_date: '2017-02-15',
          unity: school_calendars.last.unity,
          school_calendar: school_calendars.last,
          period: Periods::MATUTINAL
        )
      }
      let!(:vespertine_frequency) {
        create(
          :daily_frequency,
          classroom: vespertine_classroom,
          frequency_date: '2017-02-15',
          unity: school_calendars.last.unity,
          school_calendar: school_calendars.last,
          period: Periods::VESPERTINE
        )
      }
      let!(:new_event) {
        build(
          :school_calendar_event,
          school_calendar: school_calendars.last,
          coverage: 'by_unity',
          periods: Periods::MATUTINAL,
          event_type: EventTypes::NO_SCHOOL,
          grade_id: '',
          course_id: '',
          classroom_id: '',
          show_in_frequency_record: false,
          start_date: '2017-02-15',
          end_date: '2017-02-15'
        )
      }

      subject do
        SchoolCalendarEventDays.update_school_days(
          [school_calendars.last],
          [new_event],
          'create',
          '2017-02-15',
          '2017-02-15'
        )
      end

      it 'deletes only matutinal daily_frequency' do
        expect { subject }.to change { DailyFrequency.where(id: matutinal_frequency.id).count }.by(-1)
      end

      it 'does not delete vespertine daily_frequency' do
        expect { subject }.not_to change { DailyFrequency.where(id: vespertine_frequency.id).count }
      end
    end

    context 'when by_grade event has specific period defined' do
      let!(:matutinal_frequency) {
        create(
          :daily_frequency,
          classroom: matutinal_classroom,
          frequency_date: '2017-02-15',
          unity: school_calendars.last.unity,
          school_calendar: school_calendars.last,
          period: Periods::MATUTINAL
        )
      }
      let!(:vespertine_frequency) {
        create(
          :daily_frequency,
          classroom: vespertine_classroom,
          frequency_date: '2017-02-15',
          unity: school_calendars.last.unity,
          school_calendar: school_calendars.last,
          period: Periods::VESPERTINE
        )
      }
      let!(:new_event) {
        build(
          :school_calendar_event,
          school_calendar: school_calendars.last,
          coverage: 'by_grade',
          periods: Periods::MATUTINAL,
          event_type: EventTypes::NO_SCHOOL,
          grade_id: matutinal_classroom_grade.grade_id,
          course_id: matutinal_classroom_grade.grade.course_id,
          classroom_id: '',
          show_in_frequency_record: false,
          start_date: '2017-02-15',
          end_date: '2017-02-15'
        )
      }

      subject do
        SchoolCalendarEventDays.update_school_days(
          [school_calendars.last],
          [new_event],
          'create',
          '2017-02-15',
          '2017-02-15'
        )
      end

      it 'deletes only matutinal daily_frequency from matching grade' do
        expect { subject }.to change { DailyFrequency.where(id: matutinal_frequency.id).count }.by(-1)
      end

      it 'does not delete vespertine daily_frequency' do
        expect { subject }.not_to change { DailyFrequency.where(id: vespertine_frequency.id).count }
      end
    end

    context 'when by_course event has specific period defined' do
      let!(:matutinal_frequency) {
        create(
          :daily_frequency,
          classroom: matutinal_classroom,
          frequency_date: '2017-02-15',
          unity: school_calendars.last.unity,
          school_calendar: school_calendars.last,
          period: Periods::MATUTINAL
        )
      }
      let!(:vespertine_frequency) {
        create(
          :daily_frequency,
          classroom: vespertine_classroom,
          frequency_date: '2017-02-15',
          unity: school_calendars.last.unity,
          school_calendar: school_calendars.last,
          period: Periods::VESPERTINE
        )
      }
      let!(:new_event) {
        build(
          :school_calendar_event,
          school_calendar: school_calendars.last,
          coverage: 'by_course',
          periods: Periods::MATUTINAL,
          event_type: EventTypes::NO_SCHOOL,
          grade_id: '',
          course_id: matutinal_classroom_grade.grade.course_id,
          classroom_id: '',
          show_in_frequency_record: false,
          start_date: '2017-02-15',
          end_date: '2017-02-15'
        )
      }

      subject do
        SchoolCalendarEventDays.update_school_days(
          [school_calendars.last],
          [new_event],
          'create',
          '2017-02-15',
          '2017-02-15'
        )
      end

      it 'deletes only matutinal daily_frequency from matching course' do
        expect { subject }.to change { DailyFrequency.where(id: matutinal_frequency.id).count }.by(-1)
      end

      it 'does not delete vespertine daily_frequency' do
        expect { subject }.not_to change { DailyFrequency.where(id: vespertine_frequency.id).count }
      end
    end
  end

  # Evento criado cobrindo só um turno e depois editado ampliando/alterando o turno.
  # Como a edição não muda as datas, o reprocessamento precisa do parâmetro scope_changed
  # para excluir as frequências do novo escopo.
  describe 'when the event scope changes on update' do
    let!(:matutinal_classroom) {
      create(:classroom, unity: school_calendars.last.unity, period: Periods::MATUTINAL)
    }
    let!(:vespertine_classroom) {
      create(:classroom, unity: school_calendars.last.unity, period: Periods::VESPERTINE)
    }
    let!(:matutinal_classroom_grade) {
      create(:classrooms_grade, classroom: matutinal_classroom)
    }
    let!(:vespertine_classroom_grade) {
      create(:classrooms_grade, classroom: vespertine_classroom)
    }
    let!(:matutinal_frequency) {
      create(
        :daily_frequency,
        classroom: matutinal_classroom,
        frequency_date: '2017-02-15',
        unity: school_calendars.last.unity,
        school_calendar: school_calendars.last,
        period: Periods::MATUTINAL
      )
    }
    # Frequência de um turno NÃO coberto pelo evento — deve sobreviver ao reprocessamento.
    let!(:vespertine_frequency) {
      create(
        :daily_frequency,
        classroom: vespertine_classroom,
        frequency_date: '2017-02-15',
        unity: school_calendars.last.unity,
        school_calendar: school_calendars.last,
        period: Periods::VESPERTINE
      )
    }
    let(:event) {
      build(
        :school_calendar_event,
        school_calendar: school_calendars.last,
        coverage: 'by_unity',
        periods: Periods::MATUTINAL,
        event_type: EventTypes::NO_SCHOOL,
        grade_id: '',
        course_id: '',
        classroom_id: '',
        show_in_frequency_record: false,
        start_date: '2017-02-15',
        end_date: '2017-02-15'
      )
    }

    context 'when scope_changed is true' do
      subject do
        SchoolCalendarEventDays.update_school_days(
          [school_calendars.last],
          [event],
          'update',
          Date.new(2017, 2, 15),
          Date.new(2017, 2, 15),
          scope_changed: true
        )
      end

      it 'deletes the daily_frequency of the covered period' do
        expect { subject }.to change { DailyFrequency.where(id: matutinal_frequency.id).count }.by(-1)
      end

      it 'preserves the daily_frequency of a period not covered by the event' do
        expect { subject }.not_to change { DailyFrequency.where(id: vespertine_frequency.id).count }
      end
    end

    context 'when scope_changed is false' do
      subject do
        SchoolCalendarEventDays.update_school_days(
          [school_calendars.last],
          [event],
          'update',
          Date.new(2017, 2, 15),
          Date.new(2017, 2, 15),
          scope_changed: false
        )
      end

      it 'does not delete the daily_frequency' do
        expect { subject }.not_to change { DailyFrequency.where(id: matutinal_frequency.id).count }
      end
    end

    # Muda o tipo (para outro "não permite") e o turno na mesma edição, sem mudar datas.
    # Cai no ramo do event_type_changed, cuja limpeza full-range deve usar o turno NOVO
    # (o do evento) e preservar o turno não coberto.
    context 'when the event type and the period change together' do
      subject do
        SchoolCalendarEventDays.update_school_days(
          [school_calendars.last],
          [event],
          'update',
          Date.new(2017, 2, 15),
          Date.new(2017, 2, 15),
          event_type_changed: true,
          scope_changed: true
        )
      end

      it 'deletes the frequency of the covered period' do
        expect { subject }.to change { DailyFrequency.where(id: matutinal_frequency.id).count }.by(-1)
      end

      it 'preserves the frequency of a period not covered by the event' do
        expect { subject }.not_to change { DailyFrequency.where(id: vespertine_frequency.id).count }
      end
    end

    context 'when scope_changed is true but the event type allows frequency records' do
      # Tipo que "permite lançamentos": o guard event_type_includes_no_school? deve
      # impedir a exclusão mesmo com scope_changed true.
      let(:event) {
        build(
          :school_calendar_event,
          school_calendar: school_calendars.last,
          coverage: 'by_unity',
          periods: Periods::MATUTINAL,
          event_type: EventTypes::EXTRA_SCHOOL,
          grade_id: '',
          course_id: '',
          classroom_id: '',
          show_in_frequency_record: false,
          start_date: '2017-02-15',
          end_date: '2017-02-15'
        )
      }

      subject do
        SchoolCalendarEventDays.update_school_days(
          [school_calendars.last],
          [event],
          'update',
          Date.new(2017, 2, 15),
          Date.new(2017, 2, 15),
          scope_changed: true
        )
      end

      it 'does not delete the matutinal daily_frequency' do
        expect { subject }.not_to change { DailyFrequency.where(id: matutinal_frequency.id).count }
      end

      it 'does not delete the vespertine daily_frequency' do
        expect { subject }.not_to change { DailyFrequency.where(id: vespertine_frequency.id).count }
      end
    end

    # Datas E escopo mudam na mesma edição. O diff de datas limpa o dia adicionado
    # e a remoção por escopo limpa o dia que permaneceu — sem sobreposição.
    context 'when dates and scope change together' do
      let(:event) {
        build(
          :school_calendar_event,
          school_calendar: school_calendars.last,
          coverage: 'by_unity',
          periods: Periods::MATUTINAL,
          event_type: EventTypes::NO_SCHOOL,
          grade_id: '',
          course_id: '',
          classroom_id: '',
          show_in_frequency_record: false,
          start_date: '2017-02-14',
          end_date: '2017-02-15'
        )
      }
      # Frequência matutina no dia recém-incluído pela extensão de datas (02-14).
      let!(:matutinal_frequency_added_day) {
        create(
          :daily_frequency,
          classroom: matutinal_classroom,
          frequency_date: '2017-02-14',
          unity: school_calendars.last.unity,
          school_calendar: school_calendars.last,
          period: Periods::MATUTINAL
        )
      }

      subject do
        SchoolCalendarEventDays.update_school_days(
          [school_calendars.last],
          [event],
          'update',
          Date.new(2017, 2, 15), # range antigo cobria só 02-15; 02-14 foi adicionado
          Date.new(2017, 2, 15),
          scope_changed: true
        )
      end

      it 'deletes the matutinal frequency on the added day' do
        expect { subject }.to change { DailyFrequency.where(id: matutinal_frequency_added_day.id).count }.by(-1)
      end

      it 'deletes the matutinal frequency on the day that remained' do
        expect { subject }.to change { DailyFrequency.where(id: matutinal_frequency.id).count }.by(-1)
      end

      it 'preserves the vespertine frequency of a period not covered' do
        expect { subject }.not_to change { DailyFrequency.where(id: vespertine_frequency.id).count }
      end
    end
  end
end
