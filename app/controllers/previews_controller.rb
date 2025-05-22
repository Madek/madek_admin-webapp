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
    preview = Preview.find(params[:preview_id])
    return unless preview && preview.file_path
    send_file preview.file_path,
              type: preview.content_type,
              disposition: 'inline'
  end
end
