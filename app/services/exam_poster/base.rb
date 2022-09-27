module ExamPoster
  class Base
    class InvalidClassroomError < StandardError; end

    attr_accessor :warning_messages, :requests

    def initialize(post_data, entity_id, post_data_last = nil, queue = nil, force_posting = nil)
      @post_data = post_data
      @post_data_last = post_data_last
      @entity_id = entity_id
      @worker_batch = post_data.worker_batch
      @warning_messages = []
      @requests = []
      @queue = queue || 'critical'
      @force_posting = force_posting
    end

    def self.post!(post_data, entity_id, post_data_last = nil, queue = nil, force_posting)
      new(post_data, entity_id, post_data_last, queue, force_posting).post!
    end

    def post!
      generate_requests

      @post_data.add_warning!(@warning_messages) if @warning_messages.present?

      worker_batch.update_attributes!(total_workers: requests.count)

      if requests.present?
        requests.each do |request|
          Ieducar::SendPostWorker.set(queue: @queue).perform_in(
            1.second,
            entity_id,
            @post_data.id,
            request[:request],
            request[:info],
            @queue,
            0
          )
        end
      else
        @post_data.finish!
      end
    end

    private

    attr_reader :worker_batch, :entity_id

    def step_exists_for_classroom?(classroom)
      return false if invalid_classroom_year?(classroom)

      get_step_by_step_number(classroom, @post_data.step.to_number).present?
    end

    def get_step(classroom)
      raise InvalidClassroomError if invalid_classroom_year?(classroom)

      get_step_by_step_number(classroom, @post_data.step.to_number) || @post_data.step
    end

    def same_unity?(classroom)
      classroom.unity_id == @post_data.step.school_calendar.unity_id
    end

    def get_step_by_step_number(classroom, step_number)
      current_step_exam_poster = "#{@entity_id}_#{classroom.id}_#{step_number}_current_step_exam_poster"

      Rails.cache.fetch(current_step_exam_poster, expires_in: 5.minutes) do
        StepsFetcher.new(classroom).step(step_number)
      end
    end

    def teacher
      @teacher ||= @post_data.teacher || @post_data.author.current_teacher
    end

    def classrooms
      @classrooms ||= teacher.classrooms.uniq
    end

    def classroom_ids
      @classroom_ids ||= teacher.classrooms.pluck(:id).uniq
    end

    def discipline_ids
      @discipline_ids ||= TeacherDisciplineClassroom.where(
        classroom_id: classroom_ids,
        teacher_id: teacher.id
      ).pluck(:discipline_id).uniq
    end

    def invalid_classroom_year?(classroom)
      @post_data.step.school_calendar.year != classroom.year
    end

    def can_post?(classroom)
      return false if classroom.blank?
      return false unless classroom.can_post

      classroom.post_info &&
        same_unity?(classroom) &&
        step_exists_for_classroom?(classroom)
    end

    def not_posted?(options = { classroom: nil, discipline: nil, student: nil })
      return { absence: true, numerical_exam: true, school_term_recovery: true, descriptive_exam: true, conceptual_exam: true, final_recovery: true } if @post_data_last.nil? || @force_posting

      not_posted = { absence: false, numerical_exam: false }
      exist_absence?(@post_data.post_type, not_posted, options)
      exist_numerical_exam?(@post_data.post_type, not_posted, options)
      exist_school_term_recovery?(@post_data.post_type, not_posted, options)
      exist_descriptive_exam?(@post_data.post_type, not_posted, options)
      exist_conceptual_exam?(@post_data.post_type, not_posted, options)
      exist_final_recovery?(@post_data.post_type, not_posted, options)
      not_posted
    end

    def exist_absence?(api_posting_type, not_posted, options)
      return unless api_posting_type.eql?(ApiPostingTypes::ABSENCE)

      if options[:discipline].present?
        daily_frequency_students = DailyFrequencyStudent.general_by_classroom_discipline_student_date_between(options[:classroom], options[:discipline], options[:student], get_step(options[:classroom]).start_at, get_step(options[:classroom]).end_at)
                                                        .by_not_poster(@post_data_last.try(:created_at))
      else
        daily_frequency_students = DailyFrequencyStudent.general_by_classroom_student_date_between(options[:classroom], options[:student], get_step(options[:classroom]).start_at, get_step(options[:classroom]).end_at)
                                                        .by_not_poster(@post_data_last.try(:created_at))
      end

      not_posted[:absence] = daily_frequency_students.try(:any?)
    end

    def exist_numerical_exam?(api_posting_type, not_posted, options)
      return unless api_posting_type.eql?(ApiPostingTypes::NUMERICAL_EXAM)

      student_recovery = RecoveryDiaryRecordStudent.by_student_id(options[:student])
                                                   .by_not_poster(@post_data_last.try(:created_at))

      daily_note_student = DailyNoteStudent.by_discipline_id(options[:discipline])
                                           .by_classroom_id(options[:classroom])
                                           .by_student_id(options[:student])
                                           .by_test_date_between(get_step(options[:classroom]).start_at, get_step(options[:classroom]).end_at)
                                           .by_not_poster(@post_data_last.try(:created_at))

      not_posted[:numerical_exam] = student_recovery.try(:any?) || daily_note_student.try(:any?)
    end

    def exist_school_term_recovery?(api_posting_type, not_posted, options)
      return unless api_posting_type.eql?(ApiPostingTypes::SCHOOL_TERM_RECOVERY)

      school_term_recovery_diary_records = SchoolTermRecoveryDiaryRecord.by_classroom_id(options[:classroom])
                                                                       .by_discipline_id(options[:discipline])
                                                                       .by_step_id(
                                                                         options[:classroom],
                                                                         get_step(options[:classroom]).id
                                                                       )

      return unless school_term_recovery_diary_records.any?

      student_recoveries = []

      school_term_recovery_diary_records.each do |school_term_recovery_diary_record|
        student_recoveries.push RecoveryDiaryRecordStudent.by_student_id(options[:student])
                                                     .by_recovery_diary_record_id(
                                                       school_term_recovery_diary_record.recovery_diary_record_id
                                                     ).by_not_poster(@post_data_last.try(:created_at))
      end

      student_recoveries.reject! { |c| c.empty? }

      not_posted[:school_term_recovery] = student_recoveries.try(:any?)
    end

    def exist_descriptive_exam?(api_posting_type, not_posted, options)
      return unless api_posting_type.eql?(ApiPostingTypes::DESCRIPTIVE_EXAM)

      descriptive_exam_students = DescriptiveExamStudent.by_classroom_and_discipline(options[:classroom], options[:discipline])
                                                        .by_student_id(options[:student])
                                                        .by_not_poster(@post_data_last.try(:created_at))

      not_posted[:descriptive_exam] = descriptive_exam_students.try(:any?)
    end

    def exist_conceptual_exam?(api_posting_type, not_posted, options)
      return unless api_posting_type.eql?(ApiPostingTypes::CONCEPTUAL_EXAM)

      conceptual_exams = ConceptualExam.by_classroom_id(options[:classroom])
                                      .by_student_id(options[:student])
                                      .by_discipline(options[:discipline])

      return unless conceptual_exams.any?

      conceptual_exam_values = []

      conceptual_exams.each do |conceptual_exam|
        conceptual_exam_values.push conceptual_exam.conceptual_exam_values.by_not_poster(@post_data_last.try(:created_at))
      end

      conceptual_exam_values.reject! { |c| c.empty? }

      not_posted[:conceptual_exam] = conceptual_exam_values.try(:any?)
    end

    def exist_final_recovery?(api_posting_type, not_posted, options)
      return unless api_posting_type.eql?(ApiPostingTypes::FINAL_RECOVERY)

      final_recovery_diary_record = FinalRecoveryDiaryRecord.by_classroom_id(options[:classroom])
                                                            .by_discipline_id(options[:discipline])
                                                            .first

      return unless final_recovery_diary_record

      student_recoveries = RecoveryDiaryRecordStudent.by_student_id(options[:student])
                                                     .by_recovery_diary_record_id(
                                                       final_recovery_diary_record.recovery_diary_record_id
                                                     ).by_not_poster(@post_data_last.try(:created_at))

      not_posted[:final_recovery] = student_recoveries.try(:any?)
    end
  end
end
