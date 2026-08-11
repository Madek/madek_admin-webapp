class ZencoderJobsController < ApplicationController
  self.admin_permission_key = :entries

  def show
    @zencoder_job = ZencoderJob.find(params[:id])
    @zencoder_job.fetch_progress if @zencoder_job.submitted?
  end
end
