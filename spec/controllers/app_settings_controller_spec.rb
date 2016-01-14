require 'spec_helper'

describe AppSettingsController do
  let(:admin_user) { create :admin_user }
  let(:app_settings) { AppSetting.first }
  before(:each) do
    unless AppSetting.first
      create :app_settings, id: 0
    end
  end

  describe '#index' do
    it 'responds with status code 200' do
      get :index, nil, user_id: admin_user.id

      expect(response).to be_success
      expect(response).to have_http_status(200)
    end
  end

  describe '#edit' do
    it 'assigns @field a proper setting' do
      get :edit, { id: 'title' }, user_id: admin_user.id
      expect(assigns[:app_settings]).to eq app_settings
      expect(assigns[:field]).to eq 'title'
      expect(response).to render_template :edit
    end

    it 'assigns @field a proper yaml setting' do
      get :edit, { id: 'sitemap' }, user_id: admin_user.id
      expect(assigns[:app_settings]).to eq app_settings
      expect(assigns[:field]).to eq 'sitemap'
      expect(response).to render_template :edit
    end
  end

  describe '#update' do
    it 'redirects to app_settings#index after successful update' do
      patch(
        :update,
        { id: app_settings.id, app_setting: { title: 'NEW TITLE' } },
        user_id: admin_user.id
      )

      expect(response).to have_http_status(302)
      expect(response).to redirect_to app_settings_path
    end

    it 'updates a setting' do
      patch(
        :update,
        { id: app_settings.id, app_setting: { site_title: 'NEW TITLE' } },
        user_id: admin_user.id
      )

      expect(flash[:success]).to eq flash_message(:update, :success)
      expect(app_settings.reload.site_title).to eq 'NEW TITLE'
    end

    it 'updates a yaml setting' do
      yaml = "---\n" \
        "- About the project: http://www.test.ch/?test\n" \
        "- Impressum: http://www.test.ch/index.php?id=12970\n" \
        "- Contact: http://www.test.ch/index.php?id=49591\n" \
        "- Help: http://wiki.test.ch/test-hilfe\n" \
        "- Terms of Use: https://wiki.test.ch/test-hilfe/doku.php?id=terms\n" \
        "- Archivierungsrichtlinien ZHdK: http://www.test.ch/?archivierung\n"

      patch(
        :update,
        { id: app_settings.id, app_setting: { sitemap: yaml } },
        user_id: admin_user.id
      )

      expect(flash[:success]).to eq flash_message(:update, :success)
      expect(app_settings.reload.sitemap.to_yaml).to eq yaml
    end
  end

  def flash_message(action, type)
    I18n.t type, scope: "flash.actions.#{action}", resource_name: 'App setting'
  end
end
