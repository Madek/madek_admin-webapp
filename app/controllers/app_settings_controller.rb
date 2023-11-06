class AppSettingsController < ApplicationController

  before_action :set_app_settings
  helper_method :edit_partials

  SETTINGS_GROUPS = {
    # hash keys == table rows; grouping and descriptions for displaying only
    'General' => {
      site_titles: 'Name of this instance',
      brand_texts: 'Name of provider of this instance',
      provenance_notices: 'Notice of provenience for content in this instance, '\
        'for example included when exporting Metadata',
      brand_logo_url: 'URL to an image'
    },
    'Welcome message (on home page)' => {
      welcome_titles: 'Title of welcome box',
      welcome_texts: 'Markdown text of welcome box'
    },
    'Other' => {
      sitemap: 'Links for footer menu',
      about_pages:
        'HTML/Markdown Content for "About Page" <code class="black">(/about)</code>'
        .html_safe,
      static_pages:
        'HTML/Markdown Content for "Static Pages" <code class="black">(/about/:page_name)</code>'
        .html_safe,
      support_urls: 'Link for support tab',
      ignored_keyword_keys_for_browsing: 'MetaKeys of type Keyword that are ' \
        'ignored for the feature "Browse similar entries (Stöbern)"',
      edit_meta_data_power_users_group_id: 'Edit Meta-Data Power-Users Group-ID',
      users_active_until_ui_default: 'Active until default for new user form (in days)'
    },
    'Copyright/License Defaults' => {
      media_entry_default_license_meta_key: 'MetaKey ID MediaEntry Licenses',
      media_entry_default_license_id: 'Keyword UUID for License set on upload',
      media_entry_default_license_usage_meta_key: \
        'MetaKey ID for MediaEntry Usage Text',
      media_entry_default_license_usage_text: 'Usage Text set on upload',
      copyright_notice_default_text: 'Default Text for Copyright Notice',
      copyright_notice_templates: 'List of copyright notice templates'
    }
  }.freeze

  CONTEXT_FOR_VIEWS = {
    context_for_entry_summary: {
      title: 'Summary Context for Entry View',
      description: 'The MetaData in this Context are shown on the \
      Detail-View, left to the Media Preview.'
    },
    context_for_collection_summary: {
      title: 'Summary Context for Collection View',
      description: 'The MetaData in this Context are shown on the \
      Detail-View, left to the Media Preview.'
    },
    contexts_for_entry_extra: {
      title: 'Extra Contexts for Entry View',
      description: 'Up to 4 Contexts showing more info on  \
      a MediaEntry page (bottom).'
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
    contexts_for_entry_validation: {
      title: 'Contexts for MediaEntry Validation',
      description: ''
    },
    contexts_for_dynamic_filters: {
      title: 'Contexts for Dynamic Filters',
      description: ''
    }
  }.freeze

  EXPLORE_PAGE_SETTINGS = {
    catalog_titles: {
      label: 'Catalog: Name',
      description: ''
    },
    catalog_subtitles: {
      label: 'Catalog: Subtitle',
      description: ''
    },
    catalog_context_keys: {
      label: 'Catalog: ContextKeys',
      description: 'List of ContextKeys that are displayed as sections of \
      the Catalog'
    },
    featured_set_titles: {
      label: 'Featured Content: Title',
      description: ''
    },
    featured_set_subtitles: {
      label: 'Featured Content: Subtitle',
      description: ''
    },
    featured_set_id: {
      label: 'Featured Content: Set',
      description: "Contents of this Set will be displayed as \
                   'Featured Content'"
    }
  }.freeze

  def index
    @static_pages = StaticPage.all
  end

  def edit
    @field = params[:id]
  end

  def update
    # replace "" with nil, but only for `app_settings.section_meta_key_id`
    data = app_setting_params[:section_meta_key_id] == "" ? 
      { section_meta_key_id: nil } : 
      app_setting_params
    @app_settings.update!(data)

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
      Settings, blacklist: %w(secret password api_key geheim))
  end

  def app_setting_params
    params.require(:app_setting).permit!
  end

  def edit_partials
    %w(
      copyright_notice_templates
    )
  end
end
