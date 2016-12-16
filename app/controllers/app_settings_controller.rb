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
    context_for_entry_summary: {
      title: 'Summary Context for Entry View',
      description: "The MetaData in this Context are shown on the \
                    Detail-View, left to the Media Preview."
    },
    context_for_collection_summary: {
      title: 'Summary Context for Collection View',
      description: "The MetaData in this Context are shown on the \
                    Detail-View, left to the Media Preview."
    },
    contexts_for_entry_extra: {
      title: 'Extra Contexts for Entry View',
      description: "Up to 4 Contexts showing more info on \
                    a MediaEntry page (bottom)."
    },
    contexts_for_collection_extra: {
      title: 'Extra Contexts for Collection View',
      description: 'List of Contexts displayed as tabs on Collection page.'
    },
    contexts_for_entry_edit: {
      title: 'Contexts for MediaEntry Edit',
      description: ''
    },
    contexts_for_collection_edit: {
      title: 'Contexts for Set Edit',
      description: ''
    },
    contexts_for_list_details: {
      title: 'Contexts for "List" View',
      description: 'Up to 3 contexts, used in \'list\' mode on index views.'
    },
    contexts_for_validation: {
      title: 'Contexts for Validation',
      description: ''
    },
    contexts_for_dynamic_filters: {
      title: 'Contexts for Dynamic Filters',
      description: ''
    }
  }.freeze

  EXPLORE_PAGE_SETTINGS = {
    catalog_title: {
      label: 'Catalog: Name',
      description: ''
    },
    catalog_subtitle: {
      label: 'Catalog: Subtitle',
      description: ''
    },
    catalog_context_keys: {
      label: 'Catalog: ContextKeys',
      description: "List of ContextKeys that are displayed as sections of \
                    the Catalog"
    },
    featured_set_title: {
      label: 'Featured Content: Title',
      description: ''
    },
    featured_set_subtitle: {
      label: 'Featured Content: Subtitle',
      description: ''
    },
    featured_set_id: {
      label: 'Featured Content: Set',
      description: "Contents of this Set will be displayed as \
                   'Featured Content'"
    },
    teaser_set_id: {
      label: 'Teaser: Set',
      description: 'Contents of this Set will be displayed as "Teaser" Collages'
    }
  }.freeze

  def index
  end

  def edit
    @field = params[:id]
  end

  def update
    prepare_params

    @app_settings.update!(app_setting_params)

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
    @explore_page_settings = EXPLORE_PAGE_SETTINGS
    @deploy_config = ApplicationHelper.unwrap_and_hide_secrets(
      Settings, blacklist: %w(secret api_key geheim))
  end

  def app_setting_params
    params.require(:app_setting).permit!
  end

  def prepare_params
    # all 'json' settings are shown and edited as yaml, transform them here:
    params.try(:[], :app_setting).each do |attr, value|
      if attr_with_type?(attr, 'jsonb')
        params[:app_setting][attr] = YAML.safe_load(value)
      elsif attr.to_s =~ /contexts|_keys/
        params[:app_setting][attr] =
          params[:app_setting][attr].split(',').map(&:strip)
      end
    end
  end

  def attr_with_type?(column, type)
    column_info(column).try(:sql_type) == type
  end

  def column_info(attr)
    ::AppSetting.columns_hash[attr.to_s]
  end

end
