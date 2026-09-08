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

  class_attribute :admin_permission_key

  protect_from_forgery

  # https://github.com/Madek/Madek/issues/423
  before_action do
    begin
      session.exists?
    rescue JSON::ParserError
      cookies.delete(Madek::Constants::AdminWebapp::SESSION_NAME)
    end
  end

  before_action :authorize_admin_permission, except: :status
  before_action :set_context_for_app_layout
  before_action :notify_if_session_expiring_soon
  before_action :forget_vocabulary_url_params_if_requested
  before_action :forget_context_permission_url_params_if_requested

  around_action :run_in_savepoint_transaction

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

  # Heals the connection (see #946) right before any response is produced, so
  # a controller that rescues a DB error itself (e.g. UsersController#destroy)
  # and then renders/redirects doesn't hit the still-aborted connection.
  def render(...)
    heal_transaction_if_aborted
    super
  end

  def redirect_to(...)
    heal_transaction_if_aborted
    super
  end

  private

  # Madek::Middleware::Audit wraps every unsafe-method request in one outer
  # transaction. A DB-level error during the action aborts that transaction at
  # the connection level, which would otherwise stay aborted (breaking further
  # queries, e.g. the error page's own nav bar) until the middleware's COMMIT.
  # Running the action in a savepoint lets `render`/`redirect_to` above roll
  # back to just that savepoint instead, healing the connection while leaving
  # the outer transaction (and deferred-constraint timing) untouched. See #946.
  def run_in_savepoint_transaction
    return yield unless ActiveRecord::Base.connection.transaction_open?

    ActiveRecord::Base.transaction(requires_new: true) do
      yield
      raise ActiveRecord::Rollback if transaction_aborted?
    end
  end

  def heal_transaction_if_aborted
    return unless transaction_aborted?

    connection = ActiveRecord::Base.connection
    savepoint = connection.current_savepoint_name
    connection.rollback_to_savepoint(savepoint) if savepoint
  end

  def transaction_aborted?
    connection = ActiveRecord::Base.connection
    connection.transaction_open? &&
      connection.raw_connection.transaction_status == PG::PQTRANS_INERROR
  end

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

  def forget_context_permission_url_params_if_requested
    if params[:reset_context_permission_params]
      context_permission_url_params.each do |key|
        session[key] = nil
      end
    end
  end

  def remember_context_permission_url_params
    context_permission_url_params.each do |key|
      session[key] = params[key] if params[key].present?
    end
  end

  def context_permission_url_params
    %i(
      context_permission_context_id
      context_permission_id
      context_permission_is_persisted
    )
  end

  def authorize_admin_permission
    authorize admin_permission_key, :has_permission?, policy_class: AdminPolicy
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
