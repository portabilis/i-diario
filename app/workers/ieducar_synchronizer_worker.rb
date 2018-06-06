class IeducarSynchronizerWorker
  include Sidekiq::Worker

  def perform(entity_id = nil, synchronization_id = nil)
    if entity_id
      entity = Entity.find(entity_id)
      perform_for_entity(entity, synchronization_id)
    else
      all_entities.each do |entity|
        IeducarSynchronizerWorker.perform_async(entity.id, synchronization_id)
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

      worker_batch = WorkerBatch.create!(main_job_class: 'IeducarSynchronizerWorker', main_job_id: synchronization.job_id)

      total = []

      increment_total(total) do
        #KnowledgeAreasSynchronizerWorker.perform_async(entity.id, synchronization.id, worker_batch.id)
        KnowledgeAreasSynchronizer.synchronize!(synchronization, worker_batch)
      end

      increment_total(total) do
        #DisciplinesSynchronizerWorker.perform_async(entity.id, synchronization.id, worker_batch.id)
        DisciplinesSynchronizer.synchronize!(synchronization, worker_batch)
      end

      increment_total(total) do
        #StudentsSynchronizerWorker.perform_async(entity.id, synchronization.id, worker_batch.id)
        StudentsSynchronizer.synchronize!(synchronization, worker_batch)
      end

      increment_total(total) do
        #DeficienciesSynchronizerWorker.perform_async(entity.id, synchronization.id, worker_batch.id)
        DeficienciesSynchronizer.synchronize!(synchronization, worker_batch)
      end

      increment_total(total) do
        #***REMOVED***sSynchronizerWorker.perform_async(entity.id, synchronization.id, worker_batch.id)
        ***REMOVED***sSynchronizer.synchronize!(synchronization, worker_batch)
      end

      increment_total(total) do
        #RoundingTablesSynchronizerWorker.perform_async(entity.id, synchronization.id, worker_batch.id)
        RoundingTablesSynchronizer.synchronize!(synchronization, worker_batch)
      end

      increment_total(total) do
        #RecoveryExamRulesSynchronizerWorker.perform_async(entity.id, synchronization.id, worker_batch.id)
        RecoveryExamRulesSynchronizer.synchronize!(synchronization, worker_batch)
      end

      increment_total(total) do
        #TeachersSynchronizerWorker.perform_async(entity.id, synchronization.id, worker_batch.id, years_to_synchronize)
        TeachersSynchronizer.synchronize!(synchronization, worker_batch, years_to_synchronize)
      end

      increment_total(total) do
        #CoursesGradesClassroomsSynchronizerWorker.perform_async(entity.id, synchronization.id, worker_batch.id)
        CoursesGradesClassroomsSynchronizer.synchronize!(synchronization, worker_batch)
      end

      increment_total(total) do
        #StudentEnrollmentDependenceSynchronizerWorker.perform_async(entity.id, synchronization.id, worker_batch.id, years_to_synchronize)
        StudentEnrollmentDependenceSynchronizer.synchronize!(synchronization, worker_batch, years_to_synchronize)
      end

      total << SpecificStepClassroomsSynchronizer.synchronize!(entity.id, synchronization.id, worker_batch.id)

      years_to_synchronize.each do |year|
        increment_total(total) do
          #ExamRulesSynchronizerWorker.perform_async(entity.id, synchronization.id, worker_batch.id, [year])
          ExamRulesSynchronizer.synchronize!(synchronization, worker_batch, [year])
        end

        Unity.with_api_code.each do |unity|
          increment_total(total) do
            #StudentEnrollmentSynchronizerWorker.perform_async(entity.id, synchronization.id, worker_batch.id, [year], unity.api_code)
            StudentEnrollmentSynchronizer.synchronize!(synchronization, worker_batch, [year], unity.api_code)
          end
        end
      end

      increment_total(total) do
        StudentEnrollmentExemptedDisciplinesSynchronizer.synchronize!(synchronization, worker_batch)
      end

      worker_batch.with_lock do
        worker_batch.update_attribute(:total_workers, total.sum)

        if worker_batch.all_workers_finished?
          synchronization.mark_as_completed!
        end
      end
    end
  end

  def years_to_synchronize
    @years ||= Unity.with_api_code.joins(:school_calendars).pluck('school_calendars.year').uniq.reject(&:blank?).sort
  end

  def all_entities
    Entity.all
  end

  def increment_total(total, &block)
    total << 1

    block.call
  end
end