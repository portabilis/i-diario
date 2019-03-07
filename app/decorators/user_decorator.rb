class UserDecorator
  include Decore
  include Decore::Proxy

  def self.data_for_select2_remote(name)
    users = User.full_name(name).ordered.map { |user|
      { id: user.id, description: user.to_s }
    }

    users.to_json
  end
end
