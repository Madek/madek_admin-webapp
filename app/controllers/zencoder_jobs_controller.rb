class ZencoderJobsController < ApplicationController
  def show
    @zencoder_job = ZencoderJob.find(params[:id])
  end
end
