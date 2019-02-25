class IeducarApiConfiguration < ActiveRecord::Base
  acts_as_copy_target

  audited

  include Audit

  has_many :synchronizations, class_name: 'IeducarApiSynchronization', dependent: :restrict_with_error

  validates :url, :token, :secret_token, :unity_code, presence: true
  validates :url, allow_blank: true, format: {
    with: /^(http|https):\/\/[a-z0-9.:]+$/,
    multiline: true,
    message: 'formato de url inválido'
  }

  def self.current
    first.presence || new
  end

  def start_synchronization(user = nil)
    synchronizations.create(status: ApiSynchronizationStatus::STARTED, author: user)
  end

  def synchronization_in_progress?
    synchronizations.started.select(:running?).any?
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

  def update_synchronized_at!
    self.synchronized_at = Time.zone.now
    save!
  end
end
