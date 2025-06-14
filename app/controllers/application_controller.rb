require 'application_responder'
# require 'inshape'

class ApplicationController < ActionController::Base
  include ActionMethods
  include MadekCookieSession
  include ResponsibleEntityPath
  include WebappPathHelpers
  include Errors
  include Pundit::Authorization

  self.responder = ApplicationResponder
  self.respond_to :html

  protect_from_forgery

  # https://github.com/Madek/Madek/issues/423
  before_action do
    begin
      session.exists?
    rescue JSON::ParserError
      cookies.delete(Madek::Constants::AdminWebapp::SESSION_NAME)
    end
  end

  before_action :authorize_admin, except: :status
  before_action :set_context_for_app_layout
  before_action :notify_if_session_expiring_soon
  before_action :forget_vocabulary_url_params_if_requested

  rescue_from ActiveRecord::ActiveRecordError,
              with: :render_error
  rescue_from Pundit::NotAuthorizedError,
              with: :error_according_to_login_state

  helper_method :capitalize_all
  helper_method :current_user
  helper_method :feature_toggle_sql_reports
  helper_method :filter_value
  helper_method :auth_anti_csrf_token

  def status
    render plain: 'OK, but we need to provide memory usage info ' \
                  'as Inshape was designed for jruby'
  end

  private

  def auth_anti_csrf_token
    cookies['madek-auth_anti-csrf-token']
  end

  def set_context_for_app_layout
    # Using this so that error template (incl. base layout) can be rendered even if exception occured on the DB-level and
    # the transaction has been closed for further DB-queries.
    @beta_tester_notifications = current_user.try(:beta_tester_notifications?)
  end

  def current_user
    @current_user ||= validate_services_session_cookie_and_get_user
  end

  def render_error(error, only_text = false)
    @error = error
    wrapper = ActionDispatch::ExceptionWrapper.new(Rails.env, @error)
    @status_code = wrapper.status_code
    if only_text
      render plain: "Error #{@status_code} - #{@error.message}",
             status: @status_code
    else
      render "/errors/#{@status_code}", status: @status_code
    end
  end

  def error_according_to_login_state(exception)
    if current_user
      raise Errors::ForbiddenError, forbidden_error_message(exception)
    else
      raise Errors::UnauthorizedError, 'Please log in!'
    end
  rescue => e
    render_error e, false
  end

  def page_params
    params.fetch(:page, 1)
  end

  def forget_vocabulary_url_params_if_requested
    if params[:reset_vocabulary_params]
      vocabulary_url_params.each do |key|
        session[key] = nil
      end
    end
  end

  def remember_vocabulary_url_params
    vocabulary_url_params.each do |key|
      session[key] = params[key] if params[key].present?
    end
  end

  def vocabulary_url_params
    %i(
      vocabulary_id
      permission_id
      is_persisted
    )
  end

  def authorize_admin
    authorize :admin, :logged_in_and_admin?
  end

  def filter_value(type, default = '')
    params.fetch(:filter, {}).fetch(type, default)
  end

  def forbidden_error_message(exception)
    if exception.policy.is_a?(GroupPolicy)
      'Access denied!'
    else
      'Admin access denied!'
    end
  end

  def feature_toggle_sql_reports
    Settings.feature_toggles.try(:admin_sql_reports) == 'on my own risk'
  end

  def valid_uuid?(uuid)
    UUIDTools::UUID_REGEXP =~ uuid
  end

  def validate_uuid!(uuid)
    raise 'Not an UUID!' unless valid_uuid?(uuid)
  end

  def capitalize_all(str)
    str.split.map(&:capitalize).join(' ')
  end
end
