class IeducarApiConfiguration < ActiveRecord::Base
  acts_as_copy_target

  audited

  include Audit

  has_many :synchronizations, class_name: "IeducarApiSynchronization"

  validates :url, :token, :secret_token, :unity_code, presence: true
  validates :url, format: { with: /^(http|https):\/\/[a-z0-9.:]+$/, multiline: true, message: "formato de url inválido" }, allow_blank: true

  def self.current
    self.first.presence || new
  end

  def start_synchronization(user = nil)
    synchronizations.create(status: ApiSynchronizationStatus::STARTED, author: user)
  end

  def synchronization_in_progress?
    synchronizations.started.exists?
  end

  def authenticate!(token)
    self.token == token
  end

  def to_api
    {
      url: url,
      access_key: token,
      secret_key: secret_token,
      unity_id: unity_code
    }
  end
end
