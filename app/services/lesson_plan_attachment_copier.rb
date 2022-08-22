class LessonPlanAttachmentCopier
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

    @new_lesson_plan.lesson_plan.lesson_plan_attachments.each do |attachment|
      filename = attachment.filename
      original_id = @original_attachments[filename]
      new_id = attachment.id

      if UploadsStorage.s3?
        begin
          s3_handler = AwsS3HandlerService.new
          s3_handler.copy_object("#{prefix}/#{original_id}/#{filename}", "#{prefix}/#{new_id}/#{filename}", @new_lesson_plan )
        rescue Aws::S3::Errors::NoSuchKey
          attachment.destroy
        rescue StandardError => error
          Honeybadger.notify(error)
          next
        end
      else
        uploads = "#{Rails.root}/public/#{prefix}"

        FileUtils.mkdir_p("#{uploads}/#{new_id}")
        FileUtils.cp("#{uploads}/#{original_id}/#{filename}", "#{uploads}/#{new_id}/#{filename}")
      end
    end
  end
end
