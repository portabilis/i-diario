class BaseSynchronizer
  class << self
    def synchronize!(params)
      worker_batch = params[:worker_batch]
      worker_state = WorkerState.find(params[:worker_state_id])
      worker_state.start!

      new(
        params.slice(
          :synchronization,
          :worker_batch,
          :year,
          :unity_api_code,
          :entity_id,
          :current_years
        ).merge(
          worker_state: worker_state
        )
      ).synchronize!

      worker_batch.increment
      finish_worker(worker_state, worker_batch, params[:synchronization])
      SynchronizerBuilderEnqueueWorker.set(
        queue: params[:synchronization].full_synchronization? ? :synchronizer_enqueue_next_job_full : :synchronizer_enqueue_next_job
      ).perform_in(
        1.second,
        synchronizer_builder_enqueue_worker_params(params, worker_batch.id)
      )
    rescue StandardError => error
      unity = error.try(:record).try(:unity)
      unity ||= error.try(:record).try(:school_calendar).try(:unity)
      unity = "#{unity.api_code} - #{unity.name}: " if unity.present?
      error_message = "#{unity}#{error.message}"

      worker_state.mark_with_error!(error_message) if error.message != '502 Bad Gateway'

      raise error
    end

    private

    def finish_worker(worker_state, worker_batch, synchronization)
      worker_state.end! unless worker_state.completed? || worker_state.error?
      worker_batch.mark_as_error! if worker_state.error? && !worker_batch.error?

      return unless worker_batch.all_workers_finished?

      if worker_batch.error?
        synchronization.mark_as_error!(I18n.t('ieducar_api.error.messages.sync_error'))
      else
        synchronization.mark_as_completed!
      end
    end

    def worker_name
      to_s
    end

    def synchronizer_builder_enqueue_worker_params(params, worker_batch_id)
      params.slice(
        :entity_id,
        :year,
        :unity_api_code,
        :current_years
      ).merge(
        klass: worker_name,
        synchronization_id: params[:synchronization].id,
        worker_batch_id: worker_batch_id
      )
    end
  end

  def initialize(params)
    self.synchronization = params[:synchronization]
    self.worker_batch = params[:worker_batch]
    self.worker_state = params[:worker_state]
    self.entity_id = params[:entity_id]
    self.year = params[:year]
    self.unity_api_code = params[:unity_api_code]
    self.current_years = params[:current_years]
    self.filtered_by_unity = params[:filtered_by_unity]
  end

  protected

  attr_accessor :synchronization, :worker_batch, :worker_state, :entity_id, :year, :unity_api_code,
                :filtered_by_year, :filtered_by_unity, :current_years

  def api
    @api = api_class.new(synchronization.to_api, synchronization.full_synchronization)
  end

  def api_class
    IeducarApi::Base
  end

  def unity(api_code)
    get_record(:@unities, Unity, api_code)
  end

  def preload_unities(api_code)
    preload_records(:@unities, Unity, api_code)
  end

  def teacher(api_code)
    get_record(:@teachers, Teacher, api_code, with_discarded: true)
  end

  def preload_teachers(api_code)
    preload_records(:@teachers, Teacher, api_code, with_discarded: true)
  end

  def student(api_code)
    get_record(:@students, Student, api_code, with_discarded: true)
  end

  def preload_students(api_code)
    preload_records(:@students, Student, api_code, with_discarded: true)
  end

  def student_enrollment(api_code)
    get_record(:@student_enrollments, StudentEnrollment, api_code, with_discarded: true)
  end

  def preload_student_enrollments(api_code)
    preload_records(:@student_enrollments, StudentEnrollment, api_code, with_discarded: true)
  end

  def exam_rule(api_code)
    get_record(:@exam_rules, ExamRule, api_code)
  end

  def preload_exam_rules(api_code)
    preload_records(:@exam_rules, ExamRule, api_code)
  end

  def course(api_code)
    get_record(:@course, Course, api_code, with_discarded: true)
  end

  def preload_courses(api_code)
    preload_records(:@course, Course, api_code, with_discarded: true)
  end

  def grade(api_code)
    get_record(:@grade, Grade, api_code, with_discarded: true)
  end

  def preload_grades(api_code)
    preload_records(:@grade, Grade, api_code, with_discarded: true)
  end

  def classroom(api_code)
    get_record(:@classrooms, Classroom, api_code, with_discarded: true)
  end

  def preload_classrooms(api_code)
    preload_records(:@classrooms, Classroom, api_code, with_discarded: true)
  end

  def discipline(api_code)
    get_record(:@disciplines, Discipline, api_code)
  end

  def preload_disciplines(api_code)
    preload_records(:@disciplines, Discipline, api_code)
  end

  def knowledge_area(api_code)
    get_record(:@knowledge_areas, KnowledgeArea, api_code, with_discarded: true)
  end

  def preload_knowledge_areas(api_code)
    preload_records(:@knowledge_areas, KnowledgeArea, api_code, with_discarded: true)
  end

  def rounding_table(api_code)
    get_record(:@rounding_tables, RoundingTable, api_code)
  end

  def preload_rounding_tables(api_code)
    preload_records(:@rounding_tables, RoundingTable, api_code)
  end

  def get_record(cache_ivar, model, api_code, with_discarded: false)
    cache = instance_variable_get(cache_ivar) || instance_variable_set(cache_ivar, {})

    unless cache.key?(api_code.to_s)
      scope = with_discarded ? model.with_discarded : model
      cache[api_code.to_s] = scope.find_by(api_code: api_code)
    end

    cache[api_code.to_s]
  end

  def preload_records(cache_ivar, model, api_codes, with_discarded: false)
    cache   = instance_variable_get(cache_ivar) || {}
    missing = api_codes.map(&:to_s).uniq.reject { |code| cache.key?(code) }

    return if missing.empty?

    scope = with_discarded ? model.with_discarded : model
    scope.where(api_code: missing).each { |record| cache[record.api_code.to_s] = record }

    # Marca como nil os códigos não encontrados para evitar consultas futuras
    missing.each { |code| cache[code.to_s] = nil unless cache.key?(code) }

    instance_variable_set(cache_ivar, cache)
  end
end
