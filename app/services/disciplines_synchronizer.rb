class DisciplinesSynchronizer
  def self.synchronize!(synchronization)
    new(synchronization).synchronize!
  end

  def initialize(synchronization)
    self.synchronization = synchronization
  end

  def synchronize!
    update_records api.fetch["disciplinas"]
  end

  protected

  attr_accessor :synchronization

  def api
    IeducarApi::Disciplines.new(synchronization.to_api)
  end

  def update_records(collection)
    ActiveRecord::Base.transaction do
      collection.each do |record|
        if discipline = disciplines.find_by(api_code: record["id"])
          discipline.update(description: record["nome"])
        elsif record["nome"].present?
          disciplines.create!(
            api_code: record["id"],
            description: record["nome"]
          )
        end
      end
    end
  end

  def disciplines(klass = Discipline)
    klass
  end
end
