class LessonPlanAttachmentCopier
  class AttachmentCopyError < RuntimeError; end

  class AttachmentCopyErrorNotExisted < StandardError; end

  def self.copy!(new_lesson_plan_id, klass, original_attachments)
    new(new_lesson_plan_id, klass, original_attachments).copy
  end

  def initialize(new_lesson_plan_id, klass, original_attachments)
    @new_lesson_plan = klass.constantize.find_by(id: new_lesson_plan_id)
    @original_attachments = original_attachments
  end

  def copy
    return if @new_lesson_plan.blank? || @original_attachments.blank?

    prefix = "#{Rails.env}/lesson_plan_attachments"

    @new_lesson_plan.lesson_plan.lesson_plan_attachments.map do |attachment|
      copy_attachments(prefix, attachment)
    end
  end

  def copy_attachments(prefix, attachment)
    filename = attachment.filename
    original_id = @original_attachments[filename]
    new_id = attachment.id

    if UploadsStorage.s3?
      copy_to_s3(prefix, original_id, new_id, filename, attachment)
    else
      copy_to_local(prefix, original_id, new_id, filename)
    end
  rescue AttachmentCopyError => error
    Honeybadger.notify(error)
    error_attachment
  rescue Errno::EISDIR => e
    FileUtils.rm_rf("#{uploads}/#{new_id}")
  rescue AttachmentCopyErrorNotExisted => error
    error
  end

  def copy_to_s3(prefix, original_id, new_id, filename, attachment)
    s3_handler = AwsS3HandlerService.new
    success_copy = s3_handler.copy_object("#{prefix}/#{original_id}/#{filename}", "#{prefix}/#{new_id}/#{filename}", @new_lesson_plan )

    unless success_copy
      attachment.destroy
      warning_attachment
    end
  end

  def copy_to_local(prefix, original_id, new_id, filename)
    uploads = "#{Rails.root}/public/#{prefix}"

    FileUtils.mkdir_p("#{uploads}/#{new_id}")
    FileUtils.cp("#{uploads}/#{original_id}/#{filename}", "#{uploads}/#{new_id}/#{filename}")
  end

  def warning_attachment
    raise AttachmentCopyErrorNotExisted, "Anexo não existente para o novo plano de aula #{@new_lesson_plan_id}"
  end

  def error_attachment
    raise AttachmentCopyError, "Erro ao copiar anexos para o novo plano de aula #{@new_lesson_plan_id}"
  end
end
