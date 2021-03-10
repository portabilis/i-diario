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

    configure_aws

    @new_lesson_plan.lesson_plan.lesson_plan_attachments.each do |attachment|
      begin
        filename = attachment.filename
        original_id = @original_attachments[filename]

        @s3_client.copy_object(
          bucket: @bucket_name,
          copy_source: "/#{@bucket_name}/#{@prefix}/#{original_id}/#{filename}",
          key: "#{@prefix}/#{attachment.id}/#{filename}"
        )
      rescue StandardError
        next
      end
    end
  end

  private

  def configure_aws
    aws_access_key_id = Rails.application.secrets[:DOC_UPLOADER_AWS_ACCESS_KEY_ID] ||
                        Rails.application.secrets[:AWS_ACCESS_KEY_ID]
    aws_secret_access_key = Rails.application.secrets[:DOC_UPLOADER_AWS_SECRET_ACCESS_KEY] ||
                            Rails.application.secrets[:AWS_SECRET_ACCESS_KEY]
    aws_region = Rails.application.secrets[:DOC_UPLOADER_AWS_REGION] || Rails.application.secrets[:AWS_REGION]
    @bucket_name = Rails.application.secrets[:DOC_UPLOADER_AWS_BUCKET] || Rails.application.secrets[:AWS_BUCKET]
    @prefix = "#{Rails.env}/lesson_plan_attachments"

    aws_credentials = Aws::Credentials.new(aws_access_key_id, aws_secret_access_key)
    @s3_client = Aws::S3::Client.new(region: aws_region, credentials: aws_credentials)
  end
end
