require 'application_responder'
require 'inshape'

class ApplicationController < ActionController::Base
  include Concerns::MadekCookieSession
  include Pundit
  include Errors

  self.responder = ApplicationResponder
  respond_to :html

  rescue_from ActiveRecord::ActiveRecordError,
              with: :render_error
  rescue_from Pundit::NotAuthorizedError,
              with: :error_according_to_login_state

  before_action :authorize_admin_if_test
  before_action :authorize_admin, except: :status

  include Concerns::ActionMethods
  before_action :forget_vocabulary_url_params_if_requested

  protect_from_forgery

  helper_method :current_user
  helper_method :filter_value

  def status
    memory_status = InShape::Memory.status
    render json: { memory: memory_status.content }, \
           status: memory_status.is_ok ? 200 : 499
  end

  private

  def current_user
    validate_services_session_cookie_and_get_user
  end

  def render_error(error, only_text = false)
    @error = error
    wrapper = ActionDispatch::ExceptionWrapper.new(Rails.env, @error)
    @status_code = wrapper.status_code
    if only_text
      render text: "Error #{@status_code} - #{@error.message}",
             status: @status_code
    else
      render "/errors/#{@status_code}", status: @status_code
    end
  end

  def error_according_to_login_state
    if current_user
      raise Errors::ForbiddenError, 'Admin access denied!'
    else
      raise Errors::UnauthorizedError, 'Please log in!'
    end
  rescue => e
    render_error e, true
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

  def authorize_admin_if_test
    if (Rails.env.test? || Rails.env.development?) && !current_user
      user = FactoryGirl.create :admin_user
      if user and user.authenticate user.password
        set_madek_session user
      end
    end
  end

  def filter_value(type, default = '')
    params.fetch(:filter, {}).fetch(type, default)
  end
end
