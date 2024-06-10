class NotificationCasesController < ApplicationController
  include ApplicationHelper

  before_action do
    unless @beta_tester_notifications
      raise("Not allowed to use this feature.")
    end
  end

  def index
    @notification_cases = NotificationCase.all
  end

  def show
    @notification_case = NotificationCase.find_by!(label: label_param)
  end

  def edit
    @notification_case = NotificationCase.find_by!(label: label_param)
  end

  def update
    @notification_case = NotificationCase.find_by!(label: label_param)
    @notification_case.update!(notification_case_params)
    redirect_to(@notification_case)
  end

  private 

  def label_param
    params.require(:id)
  end

  def notification_case_params
    params.require(:notification_case).permit(:description)
  end
end
