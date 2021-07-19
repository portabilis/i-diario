class SendExamAnotherClassroom
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(entity_id, classroom_id, student_id, discipline_id, discipline_score)
    Entity.find(entity_id).using_connection do
      api_config = IeducarApiConfiguration.current.to_api

      api = IeducarApi::PostExams.new(api_config)

      data = {
        etapa: 1,
        resource: 'notas',
        notas: {
          classroom_id => {
            student_id => {
              discipline_id => {
                'nota' => discipline_score
              }
            }
          }
        }
      }

      api.send_post(data)
    end
  end
end
