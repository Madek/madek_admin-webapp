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

    it 'groups by interface and orders by position within an interface' do
      interface_a = create(:io_interface, id: 'aaa_order')
      interface_b = create(:io_interface, id: 'bbb_order')
      a1 = create(:io_mapping, meta_key: @meta_key, io_interface: interface_a)
      b1 = create(:io_mapping, meta_key: @meta_key, io_interface: interface_b)
      a2 = create(:io_mapping, meta_key: @meta_key, io_interface: interface_a)
      b2 = create(:io_mapping, meta_key: @meta_key, io_interface: interface_b)

      get :index, session: { user_id: @admin_user.id }

      expect(assigns[:io_mappings].to_a).to eq [a1, a2, b1, b2]
    end

    it 'is reorderable when an interface is selected, also with a search term' do
      get :index,
          params: { io_interface_id: @io_interface.id, search_term: 'core' },
          session: { user_id: @admin_user.id }
      expect(assigns[:reorderable]).to be true

      get :index, params: { search_term: 'core' }, session: { user_id: @admin_user.id }
      expect(assigns[:reorderable]).to be false
    end

    it 'ignores a blank io_interface_id' do
      io_mapping = create(:io_mapping, meta_key: @meta_key, io_interface: @io_interface)

      get :index,
          params: { io_interface_id: '', search_term: '' },
          session: { user_id: @admin_user.id }

      expect(assigns[:io_mappings]).to include io_mapping
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

  context 'moving' do
    before :each do
      @other_interface = create(:io_interface)
      @m1 = create(:io_mapping, meta_key: @meta_key, io_interface: @io_interface)
      @o1 = create(:io_mapping, meta_key: @meta_key, io_interface: @other_interface)
      @m2 = create(:io_mapping, meta_key: @meta_key, io_interface: @io_interface)
      @o2 = create(:io_mapping, meta_key: @meta_key, io_interface: @other_interface)
      @m3 = create(:io_mapping, meta_key: @meta_key, io_interface: @io_interface)
    end

    def order_of(interface)
      IoMapping.where(io_interface: interface).reorder(:position).pluck(:id)
    end

    def move(direction, mapping, extra_params = {})
      patch "move_#{direction}",
            params: { id: mapping.id }.merge(extra_params),
            session: { user_id: @admin_user.id }
    end

    {
      up: %i(m2 m1 m3),
      down: %i(m1 m3 m2),
      to_top: %i(m2 m1 m3),
      to_bottom: %i(m1 m3 m2)
    }.each do |direction, expected|
      it "#move_#{direction} reorders only the mapping's interface " \
         'and redirects to its list' do
        move(direction, @m2)

        expect(response).to redirect_to(io_mappings_path(io_interface_id: @io_interface.id))
        expect(flash[:success]).to be_present
        expect(order_of(@io_interface))
          .to eq expected.map { |m| instance_variable_get("@#{m}").id }
        expect(order_of(@other_interface)).to eq [@o1, @o2].map(&:id)
      end

      it "#move_#{direction} is forbidden without the io permission" do
        @admin_user.admin.admin_permissions.where(permission_key: 'io').destroy_all

        move(direction, @m2)

        expect(response).to have_http_status(:forbidden)
        expect(order_of(@io_interface)).to eq [@m1, @m2, @m3].map(&:id)
      end

      it "#move_#{direction} renders 404 for an unknown mapping" do
        patch "move_#{direction}",
              params: { id: SecureRandom.uuid },
              session: { user_id: @admin_user.id }
        expect(response).to have_http_status(404)
        expect(response).to render_template 'errors/404'
      end
    end

    it 'keeps the page in the redirect' do
      move(:up, @m2, page: '2')
      expect(response).to redirect_to(
        io_mappings_path(io_interface_id: @io_interface.id, page: '2'))
    end

    context 'with a search term' do
      before :each do
        [@m1, @m2, @m3, @o1, @o2].each_with_index do |m, i|
          m.update_column(:key_map, "plain_#{i}")
        end
        @c1 = create(:io_mapping, meta_key: @meta_key, io_interface: @io_interface,
                                  key_map: 'core_a')
        @m4 = create(:io_mapping, meta_key: @meta_key, io_interface: @io_interface,
                                  key_map: 'plain_x')
        @c2 = create(:io_mapping, meta_key: @meta_key, io_interface: @io_interface,
                                  key_map: 'core_b')
      end

      it '#move_up swaps with the previous matching mapping and keeps the filter' do
        move(:up, @c2, search_term: 'core', page: '1')

        expect(response).to redirect_to(
          io_mappings_path(io_interface_id: @io_interface.id, search_term: 'core', page: '1'))
        expect(order_of(@io_interface))
          .to eq [@m1, @m2, @m3, @c2, @m4, @c1].map(&:id)
      end

      it 'moves like without a filter when the search term is blank' do
        move(:up, @c2, search_term: '')

        expect(response).to redirect_to(io_mappings_path(io_interface_id: @io_interface.id))
        expect(order_of(@io_interface))
          .to eq [@m1, @m2, @m3, @c1, @c2, @m4].map(&:id)
      end
    end
  end
end
