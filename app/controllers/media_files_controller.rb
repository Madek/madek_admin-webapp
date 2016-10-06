class MediaFilesController < ApplicationController
  def show
    @media_file = MediaFile.find(params[:id])
    @zencoder_jobs = @media_file.zencoder_jobs if @media_file.previews_zencoder?
  end

  def reencode
    media_file = MediaFile.find(params[:id])
    ActiveRecord::Base.transaction do
      media_file.previews.destroy_all
      ZencoderRequester.new(media_file).process
    end
    redirect_to media_file_path(media_file), flash: {
      info: 'The Media File was successfully sent to reencode.'
    }
  rescue => e
    render plain: e.message
  end
end
