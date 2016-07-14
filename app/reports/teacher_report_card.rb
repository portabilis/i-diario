class TeacherReportCard
  include ActiveModel::Model

  def initialize(configuration)
    @configuration = configuration
  end

  def build(params)
    report = api.fetch_teacher_report_card(params)

    Base64.decode64 report['encoded']
  end

  protected

  def api
    @api ||= IeducarApi::Teachers.new(@configuration.to_api)
  end
end
