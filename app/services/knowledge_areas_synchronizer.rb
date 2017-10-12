class KnowledgeAreasSynchronizer
  def self.synchronize!(synchronization)
    new(synchronization).synchronize!
  end

  def initialize(synchronization)
    self.synchronization = synchronization
  end

  def synchronize!
    update_records api.fetch["areas"]
  end

  protected

  attr_accessor :synchronization

  def api
    IeducarApi::KnowledgeAreas.new(synchronization.to_api)
  end

  def update_records(collection)
    ActiveRecord::Base.transaction do
      collection.each do |record|
        if knowledge_area = knowledge_areas.find_by(api_code: record["id"])
          knowledge_area.update(
            description: record["nome"],
            sequence: record["ordenamento_ac"]
          )
        elsif record["nome"].present?
          knowledge_areas.create!(
            api_code: record["id"],
            description: record["nome"],
            sequence: record["ordenamento_ac"]
          )
        end
      end
    end
  end

  def knowledge_areas(klass = KnowledgeArea)
    klass
  end
end
