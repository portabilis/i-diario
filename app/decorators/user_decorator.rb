class UserDecorator
  include Decore
  include Decore::Proxy

  def self.data_for_select2(users)
    users = users.map { |user|
      { id: user.id, name: user.to_s }
    }

    insert_empty_element(users) if users.any?

    users.to_json
  end

  def self.data_for_select2_remote(name)
    users = User.by_name(name).ordered.map { |user|
      { id: user.id, description: user.to_s }
    }

    users.to_json
  end

  def self.insert_empty_element(elements)
    empty_element = { id: 'empty', name: '<option></option>' }
    elements.insert(0, empty_element)
  end
end
