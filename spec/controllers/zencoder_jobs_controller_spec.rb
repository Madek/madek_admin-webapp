require 'spec_helper'

describe ZencoderJobsController do
  let(:admin_user) { create :admin_user }
  let(:zencoder_job) { create :zencoder_job }

  describe '#show' do
    before do
      get(
        :show,
        params: { id: zencoder_job.id },
        session: { user_id: admin_user.id })
    end

    it 'responds with 200 HTTP status code' do
      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it 'assigns @zencoder_job correctly' do
      expect(assigns[:zencoder_job]).to eq zencoder_job
    end
  end
end
