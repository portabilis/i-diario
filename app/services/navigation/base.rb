module Navigation
  class Base
    MENU = YAML.safe_load(
      ERB.new(Rails.root.join('config', 'navigation.yml').open.read).result
    )['navigation']

    def self.build(*args)
      new(*args).build
    end

    def initialize(item, user, render = Navigation::Render::Base)
      @item = item.to_s
      @navigation_render = render.new(user)
      @navigation = MENU
    end

    def build
    end

    protected

    attr_reader :navigation, :item, :navigation_render

    def menus
      @menus ||= []
    end
  end
end

