class AppSettingsController < ApplicationController

  before_action :set_app_settings

  SETTINGS_GROUPS = {
    # hash keys == table rows; grouping and descriptions for displaying only
    'General' => {
      site_title: 'Name of this instance',
      brand_text: 'Name of provider of this instance',
      brand_logo_url: 'URL to an image'
    },
    'Welcome message (on home page)' => {
      welcome_title: 'Title of welcome box',
      welcome_text: 'Markdown text of welcome box'
    },
    'Other' => {
      sitemap: 'Links for footer menu'
    }
  }

  def index
  end

  def edit
    @field = params[:id]
  end

  def update
    # all 'json' settings are shown and edited as yaml, transform them here:
    params.try(:[], :app_setting).each do |attr, value|
      if ::AppSettings.columns_hash[attr.try(:to_s)].try(:sql_type) == 'jsonb'
        params[:app_setting][attr] = YAML.safe_load(value)
      end
    end

    @app_settings.assign_attributes(app_setting_params)
    @app_settings.save

    respond_with @app_settings, location: (lambda do
      app_settings_path
    end)
  rescue => e
    redirect_to app_settings_path, flash: { error: e.to_s }
  end

  private

  def set_app_settings
    @app_settings = AppSetting.first
    @settings_groups = SETTINGS_GROUPS
  end

  def app_setting_params
    params.require(:app_setting).permit!
  end
end
