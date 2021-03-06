class PreviewsController < ApplicationController
  def show
    @preview = Preview.find(params[:id])
  end

  def destroy
    preview = Preview.find(params[:id])
    preview.destroy!

    respond_with preview, location: (lambda do
      media_file_path(preview.media_file)
    end)
  end

  def raw_file
    file_path = Preview.find(params[:preview_id]).file_path
    return unless file_path
    send_file file_path,
              type: 'image',
              disposition: 'inline'
  end
end
