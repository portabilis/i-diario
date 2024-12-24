class KnowledgeAreaContentRecordClonerForm < ApplicationRecord
  has_no_table

  attr_accessor :knowledge_area_content_record_id, :teacher

  validates :knowledge_area_content_record_id, presence: true
  has_many :knowledge_area_content_record_item_cloner_form
  accepts_nested_attributes_for :knowledge_area_content_record_item_cloner_form, :allow_destroy => true

  def clone!
    if valid?
      begin
        ActiveRecord::Base.transaction do
          @classrooms = Classroom.where(id: knowledge_area_content_record_item_cloner_form.map(&:classroom_id).uniq)
          knowledge_area_content_record_item_cloner_form.each_with_index do |item, index|
            @current_item_index = index
            new_content_record = knowledge_area_content_record.dup
            new_content_record.teacher_id = teacher.id
            new_content_record.content_record = knowledge_area_content_record.content_record.dup
            new_content_record.content_record.teacher = teacher
            new_content_record.knowledge_areas = knowledge_area_content_record.knowledge_areas
            new_content_record.content_record.original_contents =
              knowledge_area_content_record.content_record.contents
            new_content_record.content_record.classroom = @classrooms.find_by_id(item.classroom_id)
            new_content_record.content_record.record_date = item.record_date
            new_content_record.save!
          end
          return true
        end
      rescue ActiveRecord::RecordInvalid => e
        message = e.to_s
        message.slice!("A validação falhou: ")
        message.slice!("Áreas de conhecimento ")
        errors.add(:classroom_id, "Turma #{e.record.content_record.try(:classroom)}: #{message}")
        knowledge_area_content_record_item_cloner_form[@current_item_index].errors.add(:classroom_id, message)
        return false
      end
    end
  end

  def knowledge_area_content_record
    @knowledge_area_content_record ||= KnowledgeAreaContentRecord.find(knowledge_area_content_record_id)
  end
end
