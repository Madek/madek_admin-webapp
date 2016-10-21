class ZencoderJobsController < ApplicationController
  def show
    @zencoder_job = ZencoderJob.find(params[:id])
    @zencoder_job.fetch_progress if @zencoder_job.submitted?
  end
end
