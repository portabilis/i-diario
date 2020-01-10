class RemoveClosedYearsOnSelectedProfilesWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(entity_id, unity_id, year)
    Entity.find(entity_id).using_connection do
      users = User.by_current_unity_id(unity_id)
                  .by_current_school_year(year)
                  .where.not(teacher_id: nil)

      users.each do |user|
        user.update!(
          current_school_year: nil,
          current_classroom_id: nil,
          current_discipline_id: nil
        )
      end
    end
  end
end
