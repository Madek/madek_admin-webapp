class NotificationTemplatesController < ApplicationController
  include ApplicationHelper

  before_action do
    unless current_user.beta_tester_notifications?
      raise("Not allowed to use this feature.")
    end
  end

  rescue_from Liquid::SyntaxError, with: :render_error
  rescue_from Liquid::UndefinedVariable, with: :render_error

  def index
    @notification_templates = NotificationTemplate.all
  end

  def show
    @notification_template = NotificationTemplate.find_by!(label: label_param)
  end

  def edit
    @notification_template = NotificationTemplate.find_by!(label: label_param)
  end

  def update
    @notification_template = NotificationTemplate.find_by!(label: label_param)
    @notification_template.update!(notification_template_params)
    redirect_to(@notification_template)
  end

  private 

  def label_param
    params.require(:id)
  end

  def notification_template_params
    cs_with_langs = NotificationTemplate::CATEGORIES.map { |c| [c, [:en, :de]] }.to_h
    params
      .require(:notification_template)
      .permit(:description, **cs_with_langs)
      .transform_values do |v|
        if v.is_a?(String)
          sanitize_newlines(v)
        else
          v.transform_values do |v|
            sanitize_newlines(v)
          end
        end
      end
  end

  def sanitize_newlines(s)
    s.gsub(/\r\n?/, "\n")
  end
end
