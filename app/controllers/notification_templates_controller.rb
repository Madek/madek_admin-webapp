class NotificationTemplatesController < ApplicationController
  include ApplicationHelper

  before_action do
    unless current_user.beta_tester_notifications?
      raise("Not allowed to use this feature.")
    end
  end

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
    params.require(:notification_template)
      .permit(:description,
              :ui_en, :ui_de,
              :email_single_en, :email_single_de,
              :email_summary_en, :email_summary_de)
  end
end
