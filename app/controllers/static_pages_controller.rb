class StaticPagesController < ApplicationController
  include LocalizedFieldParams

  helper_method :default_locale

  def new
    @static_page = StaticPage.new
  end

  def create
    static_page = StaticPage.create!(static_page_params)

    respond_with static_page, location: -> { return_path }
  end

  def edit
    @static_page = find_static_page
  end

  def update
    static_page = find_static_page
    static_page.update!(static_page_params)

    respond_with static_page, location: -> { return_path }
  end

  def destroy
    static_page = find_static_page
    static_page.destroy!

    respond_with static_page, location: -> { return_path }
  end

  private

  def find_static_page
    StaticPage.find(params[:id])
  end

  def static_page_params
    params.require(:static_page).permit(:name, localized_field_params)
  end

  def return_path
    app_settings_path(anchor: 'static_pages')
  end

  def default_locale
    @_default_locale ||= AppSetting.first.default_locale
  end
end
