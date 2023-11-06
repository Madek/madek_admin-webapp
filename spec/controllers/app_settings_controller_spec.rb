require 'spec_helper'

describe AppSettingsController do
  let(:admin_user) { create :admin_user }
  let(:app_settings) { AppSetting.first }

  describe '#index' do
    it 'responds with status code 200' do
      get :index, session: { user_id: admin_user.id }

      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end
  end

  describe '#edit' do
    it 'assigns @field a proper setting' do
      get :edit, params: { id: 'title' }, session: { user_id: admin_user.id }
      expect(assigns[:app_settings]).to eq app_settings
      expect(assigns[:field]).to eq 'title'
      expect(response).to render_template :edit
    end

    it 'assigns @field a proper yaml setting' do
      get :edit, params: { id: 'sitemap' }, session: { user_id: admin_user.id }
      expect(assigns[:app_settings]).to eq app_settings
      expect(assigns[:field]).to eq 'sitemap'
      expect(response).to render_template :edit
    end
  end

  describe '#update' do
    it 'redirects to app_settings#index after successful update' do
      patch(
        :update,
        params: { id: app_settings.id, app_setting: { title: 'NEW TITLE' } },
        session: { user_id: admin_user.id }
      )

      expect(response).to have_http_status(302)
      expect(response).to redirect_to app_settings_path
    end

    it 'updates a setting' do
      patch(
        :update,
        params: {
          id: app_settings.id,
          app_setting: {
            site_titles: {
              de: 'neuer Titel',
              en: 'NEW TITLE'
            }
          }
        },
        session: { user_id: admin_user.id }
      )

      expect(flash[:success]).to eq flash_message(:update, :success)
      expect(app_settings.reload.site_title).to eq 'neuer Titel'
      expect(app_settings.reload.site_title(:en)).to eq 'NEW TITLE'
    end

    it 'updates a yaml setting' do
      new_sitemap = YAML.safe_load <<-YAML
        de:
          - "Über das Projekt": http://www.test.ch/?test
          - "Impressum": http://www.test.ch/index.php?id=12970
          - "Kontakt": http://www.test.ch/index.php?id=49591
          - "Hilfe": http://wiki.test.ch/test-hilfe
          - "Nutzungsbedingungen": https://wiki.test.ch/test-hilfe/doku.php?id=terms
          - "Archivierungsrichtlinien ZHdK": http://www.test.ch/?archivierung
        en:
          - "About the project": http://www.test.ch/?test
          - "Legal": http://www.test.ch/index.php?id=12970
          - "Contact": http://www.test.ch/index.php?id=49591
          - "Help": http://wiki.test.ch/test-hilfe
          - "Terms of Use": https://wiki.test.ch/test-hilfe/doku.php?id=terms
      YAML

      patch(
        :update,
        params: {
          id: app_settings.id,
          app_setting: { sitemap: new_sitemap.to_yaml }
        },
        session: { user_id: admin_user.id }
      )

      expect(flash[:success]).to eq flash_message(:update, :success)
      expect(app_settings.reload.sitemap).to eq new_sitemap
    end
  end

  def flash_message(action, type)
    I18n.t type, scope: "flash.actions.#{action}", resource_name: 'App setting'
  end
end
