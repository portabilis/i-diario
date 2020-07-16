require "rails_helper"

describe Navigation::MenuBuilder, type: :service do
  let :current_user do
    User.new(admin: true)
  end

  subject { described_class.new feature, current_user }

  describe "#build" do
    context "when informed feature no refers to a menu or a submenu" do
      let(:feature) { "invalid menu" }

      it "returns all menus, but no mark nothing menu or submenu as current" do
        html = subject.build

        expect(html).to match /<ul><li class="">.+Início.+<\/li>.+<\/ul>/

        expect(html).to match /<ul>.+Administrativo.+<li class="">.+Configurações gerais.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+Administrativo.+<li class="">.+Manutenção\/Ajustes.+<\/li>.+<\/ul>.+<\/ul>/

        expect(html).to match /<ul>.+Administrativo.+<li class="">.+Configurações.+<ul>.+<\/ul>.+<\/li>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul><li class="">.+Permissões.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul>.+Permissões.+<li class="">.+Unidades.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul>.+Unidades.+<li class="">.+API de integração.+<\/li>.+<\/ul>.+<\/ul>/
      end
    end

    context "when informed feature refers to a menu" do
      let(:feature) { "dashboard" }

      it "returns all menus, but only feature menu is marked as current" do
        html = subject.build

        expect(html).to match /<ul><li class="current">.+Início.+<\/li>.+<\/ul>/

        expect(html).to match /<ul>.+Administrativo.+<li class="">.+Configurações gerais.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+Administrativo.+<li class="">.+Manutenção\/Ajustes.+<\/li>.+<\/ul>.+<\/ul>/

        expect(html).to match /<ul>.+Administrativo.+<li class="">.+Configurações.+<ul>.+<\/ul>.+<\/li>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul><li class="">.+Permissões.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul>.+Permissões.+<li class="">.+Unidades.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul>.+Unidades.+<li class="">.+API de integração.+<\/li>.+<\/ul>.+<\/ul>/
      end
    end

    context "when informed feature refers to a submenu" do
      let(:feature) { "unities" }

      it "returns all menus, but only feature submenu is marked as current and your parent menu is marked as open" do
        html = subject.build

        expect(html).to match /<ul><li class="">.+Início.+<\/li>.+<\/ul>/

        expect(html).to match /<ul>.+Administrativo.+<li class="">.+Configurações gerais.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+Administrativo.+<li class="">.+Manutenção\/Ajustes.+<\/li>.+<\/ul>.+<\/ul>/

        expect(html).to match /<ul>.+Administrativo.+<li class="">.+Configurações.+<ul>.+<\/ul>.+<\/li>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul style="display: block;"><li class="">.+Permissões.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul style="display: block;">.+Permissões.+<li class="current">.+Unidades.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul style="display: block;">.+Unidades.+<li class="">.+API de integração.+<\/li>.+<\/ul>.+<\/ul>/
      end
    end

    context "when current user has limited access" do
      let(:feature) { "dashboard" }

      let :current_user do
        current_user = users(:mary_jane)
        user_role = create(:user_role, user: current_user, role: roles(:admin))
        current_user.user_roles << user_role
        current_user.save
        current_user.set_current_user_role!(user_role.id)
        current_user
      end

      it "returns all permitted menus" do
        html = subject.build

        expect(html).to_not match /<ul>.+Configurações.+<ul>.+Permissões.+<li class="">.+Unidades.+<\/li>.+<\/ul>.+<\/ul>/
        expect(html).to_not match /<ul>.+Configurações.+<ul>.+Configurações gerais.+<li class="">.+API de integração.+<\/li><\/ul>.+<\/ul>/
        expect(html).to_not match /<ul>.+Configurações.+<li class="">.+Publicações.+<\/li>.+<\/ul>/

        expect(html).to match /<ul><li class="current">.+Início.+<\/li>.+<\/ul>/
        expect(html).to match /<ul>.+Configurações.+<ul>.+Unidades.+<li class="">.+Usuários.+<\/li>.+<\/ul>.+<\/ul>/
      end
    end
  end
end
