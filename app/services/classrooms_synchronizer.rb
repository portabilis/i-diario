class ClassroomsSynchronizer
  def self.synchronize!(synchronization)
    new(synchronization).synchronize!
  end

  def initialize(synchronization)
    self.synchronization = synchronization
  end

  def synchronize!
    update_records api.fetch(ano: Date.today.year)["turmas"]
  end

  protected

  attr_accessor :synchronization

  def api
    IeducarApi::Classrooms.new(synchronization.to_api)
  end

  def update_records(collection)
    ActiveRecord::Base.transaction do
      collection.each do |record|
        if classroom = classrooms.find_by(api_code: record["id"])
          classroom.update(description: record["nome"])
        elsif record["nome"].present?
          classrooms.create!(
            api_code: record["id"],
            description: record["nome"],
            unity_id: Unity.find_by(api_code: record["escola_id"]).try(:id),
            unity_code: record["escola_id"],
            year: Date.today.year
          )
        end
      end
    end
  end

  def classrooms(klass = Classroom)
    klass
  end
end
