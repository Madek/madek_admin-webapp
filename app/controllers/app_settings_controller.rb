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
  }.freeze

  CONTEXT_FOR_VIEWS = {
    context_for_show_summary: {
      title: 'Summary Context for Detail View',
      description: "The MetaData in this Context are shown on the \
                    Detail-View, left to the Media Preview."
    },
    contexts_for_show_extra: {
      title: 'Extra Contexts for Detail View',
      description: 'Up to 4 Contexts showing more info on \
                    a MediaEntry page (bottom).'
    },
    contexts_for_list_details: {
      title: 'Contexts for "List" View',
      description: 'Up to 3 contexts, used in \'list\' mode on index views.'
    }
  }.freeze

  def index
  end

  def edit
    @field = params[:id]
  end

  def update
    prepare_params

    @app_settings.assign_attributes(app_setting_params)
    @app_settings.save!

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
    @context_for_views = CONTEXT_FOR_VIEWS
  end

  def app_setting_params
    params.require(:app_setting).permit!
  end

  def prepare_params
    # all 'json' settings are shown and edited as yaml, transform them here:
    params.try(:[], :app_setting).each do |attr, value|
      if attr_with_type?(attr, 'jsonb')
        params[:app_setting][attr] = YAML.safe_load(value)
      elsif attr.to_s.start_with?('contexts_for')
        params[:app_setting][attr] =
          params[:app_setting][attr].split(',').map(&:strip)
      end
    end
  end

  def attr_with_type?(attr, type)
    ::AppSettings.columns_hash[attr.try(:to_s)].try(:sql_type) == type
  end
end
