require 'spec_helper'

describe PreviewsController do
  let(:admin_user) { create :admin_user }
  let(:preview) { create :preview, media_file_id: create(:media_file).id }

  describe '#show' do
    before do
      get(
        :show,
        params: { id: preview.id },
        session: { user_id: admin_user.id })
    end

    it 'responds with HTTP 200 status code' do
      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'assigns @preview correctly' do
      expect(assigns(:preview)).to eq preview
    end
  end

  describe '#destroy' do
    before { @preview = create :preview, media_file_id: create(:media_file).id }

    it 'destroys preview' do
      expect do
        delete(
          :destroy,
          params: { id: @preview.id },
          session: { user_id: admin_user.id })
      end.to change { Preview.count }.by(-1)
    end

    context 'when preview is destroyed successfully' do
      it 'redirects to admin media file path with success message' do
        delete(
          :destroy,
          params: { id: @preview.id },
          session: { user_id: admin_user.id })

        expect(response).to redirect_to(media_file_path(@preview.media_file))
        expect(flash[:success]).to eq flash_message(:destroy, :success)
      end
    end

    context 'when preview does not exist' do
      it 'redirects to admin media file path with error message' do
        delete(
          :destroy,
          params: { id: UUIDTools::UUID.random_create },
          session: { user_id: admin_user.id }
        )

        expect(response).to have_http_status(:not_found)
        expect(response).to render_template 'errors/404'
      end
    end
  end

  def flash_message(action, type)
    I18n.t type, scope: "flash.actions.#{action}", resource_name: 'Preview'
  end
end
