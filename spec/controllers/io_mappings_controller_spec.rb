require 'spec_helper'

describe IoMappingsController do

  before :each do
    @admin_user = create(:admin_user)
    @io_interface = create(:io_interface)
    @meta_key = create(:meta_key_text, id: "test:#{Faker::Lorem.characters(number: 10)}")
  end

  context '#index' do
    it 'responds with 200 HTTP status code' do
      get :index, session: { user_id: @admin_user.id }

      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    context 'filtering by key map' do
      it 'returns correct collection of meta keys' do
        create(:io_mapping, meta_key: @meta_key, io_interface: @io_interface)
        io_mapping_1 = create(:io_mapping,
                              key_map: 'foo_bar',
                              meta_key: @meta_key,
                              io_interface: @io_interface)
        io_mapping_2 = create(:io_mapping,
                              key_map: 'bar_foo',
                              meta_key: @meta_key,
                              io_interface: @io_interface)

        get(
          :index,
          params: { search_term: 'foo' },
          session: { user_id: @admin_user.id })

        expect(assigns[:io_mappings]).to match_array([io_mapping_1, io_mapping_2])
      end
    end

    context 'filtering by meta key ID' do
      it 'returns correct collection of meta keys' do
        create(:io_mapping, meta_key: @meta_key, io_interface: @io_interface)
        @meta_key = create(:meta_key_text, id: 'test:foo_bar')
        io_mapping_1 = create(:io_mapping,
                              meta_key: @meta_key,
                              io_interface: @io_interface)
        io_mapping_2 = create(:io_mapping,
                              meta_key: @meta_key,
                              io_interface: @io_interface)

        get(
          :index,
          params: { search_term: 'bar' },
          session: { user_id: @admin_user.id })

        expect(assigns[:io_mappings]).to match_array([io_mapping_1, io_mapping_2])
      end
    end

    it '#update' do
      @io_mapping = create(:io_mapping,
                           meta_key: @meta_key,
                           io_interface: @io_interface)
      put(:update,
          params: {
            id: @io_mapping.id,
            io_mapping: { io_interface_id: @io_interface.id,
                          meta_key_id: @meta_key.id,
                          key_map: 'test_edit' } },
          session: { user_id: @admin_user.id })

      expect(response).to have_http_status(302)
      expect(@io_mapping.reload.key_map).to eq 'test_edit'
    end

    it '#show' do
      @io_mapping = create(:io_mapping,
                           meta_key: @meta_key,
                           io_interface: @io_interface)
      get(
        :show,
        params: { id: @io_mapping.id },
        session: { user_id: @admin_user.id })

      expect(response).to be_successful
      expect(response).to have_http_status(200)
      expect(response).to render_template :show
      expect(assigns[:io_mapping]).to eq @io_mapping
    end

    it '#destroy' do
      @io_mapping = create(:io_mapping,
                           meta_key: @meta_key,
                           io_interface: @io_interface)

      delete(
        :destroy,
        params: { id: @io_mapping.id },
        session: { user_id: @admin_user.id })
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(io_mappings_path)
    end

    it '#create' do
      io_mapping_params = {
        io_interface_id: @io_interface.id,
        meta_key_id: @meta_key.id,
        key_map: Faker::Lorem.word
      }

      expect do
        post(
          :create,
          params: { io_mapping: io_mapping_params },
          session: { user_id: @admin_user.id })
      end.to change { IoMapping.count }.by(1)
    end
  end
end
