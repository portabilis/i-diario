class IeducarSynchronizerWorker
  include Sidekiq::Worker

  def perform(entity_id = nil, synchronization_id = nil)
    if entity_id
      entity = Entity.find(entity_id)
      perform_for_entity(entity, synchronization_id)
    else
      all_entities.each do |entity|
        perform_for_entity(entity, synchronization_id)
      end
    end
  end

  private

  def perform_for_entity(entity, synchronization_id)
    entity.using_connection do
      unless synchronization = IeducarApiSynchronization.find_by_id(synchronization_id)
        configuration = IeducarApiConfiguration.current
        break unless configuration.persisted?
        synchronization = configuration.start_synchronization!(User.first)
        synchronization.job_id = self.jid unless synchronization.job_id
      end

      worker_batch = WorkerBatch.create!(main_job_id: synchronization.job_id)

      total_count = 0
      total_count += call_and_count_worker(KnowledgeAreasSynchronizerWorker, entity.id, synchronization.id, worker_batch.id)
      total_count += call_and_count_worker(DisciplinesSynchronizerWorker, entity.id, synchronization.id, worker_batch.id)
      total_count += call_and_count_worker(StudentsSynchronizerWorker, entity.id, synchronization.id, worker_batch.id)
      total_count += call_and_count_worker(DeficienciesSynchronizerWorker, entity.id, synchronization.id, worker_batch.id)
      total_count += call_and_count_worker(***REMOVED***sSynchronizerWorker, entity.id, synchronization.id, worker_batch.id)
      total_count += call_and_count_worker(RoundingTablesSynchronizerWorker, entity.id, synchronization.id, worker_batch.id)
      total_count += call_and_count_worker(RecoveryExamRulesSynchronizerWorker, entity.id, synchronization.id, worker_batch.id)
      total_count += call_and_count_worker_by_years(TeachersSynchronizerWorker, entity.id, synchronization.id, worker_batch.id, years_to_synchronize)
      total_count += call_and_count_worker(CoursesGradesClassroomsSynchronizerWorker, entity.id, synchronization.id, worker_batch.id)
      total_count += call_and_count_worker_by_years(StudentEnrollmentDependenceSynchronizerWorker, entity.id, synchronization.id, worker_batch.id, years_to_synchronize)
      total_count += SpecificStepClassroomsSynchronizer.synchronize!(entity.id, synchronization.id, worker_batch.id)

      years_to_synchronize.each do |year|
        total_count += call_and_count_worker_by_years(ExamRulesSynchronizerWorker, entity.id, synchronization.id, worker_batch.id, [year])

        Unity.with_api_code.each do |unity|
          total_count += call_and_count_worker_by_years(StudentEnrollmentSynchronizerWorker, entity.id, synchronization.id, worker_batch.id, [year], unity.api_code)
        end
      end

      worker_batch.set_total_workers!(total_count)
      worker_batch.reload

      if worker_batch.all_workers_finished?
        synchronization.mark_as_completed!
      end
    end
  end

  def years_to_synchronize
    @years ||= Unity.with_api_code.map { |unity| CurrentSchoolYearFetcher.new(unity).fetch }.uniq.reject(&:blank?).sort
  end

  def all_entities
    Entity.all
  end

  def call_and_count_worker(worker, entity_id, synchronization_id, worker_batch_id)
    worker.perform_async(entity_id, synchronization_id, worker_batch_id)

    1
  end

  def call_and_count_worker_by_years(worker, entity_id, synchronization_id, worker_batch_id, years, unity_api_code = nil)
    worker.perform_async(entity_id, synchronization_id, worker_batch_id, years, unity_api_code)

    1
  end
end
