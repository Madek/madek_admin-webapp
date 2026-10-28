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

    context 'ordering' do
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
    end

    context 'reorderable' do
      it 'is true for an interface without search term' do
        get :index,
            params: { io_interface_id: @io_interface.id, search_term: '' },
            session: { user_id: @admin_user.id }
        expect(assigns[:reorderable]).to be true
      end

      it 'is false without interface' do
        get :index, session: { user_id: @admin_user.id }
        expect(assigns[:reorderable]).to be false
      end

      it 'is false with a search term' do
        get :index,
            params: { io_interface_id: @io_interface.id, search_term: 'madek' },
            session: { user_id: @admin_user.id }
        expect(assigns[:reorderable]).to be false
      end
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

  describe '#move_up' do
    it 'swaps position with the previous mapping on the same interface and redirects' do
      earlier = create(:io_mapping, meta_key: @meta_key, io_interface: @io_interface)
      other_interface = create(:io_interface)
      other = create(:io_mapping, meta_key: @meta_key, io_interface: other_interface)
      mapping = create(:io_mapping, meta_key: @meta_key, io_interface: @io_interface)
      earlier_position = earlier.position
      mapping_position = mapping.position
      other_position = other.position

      patch :move_up,
            params: { id: mapping.id },
            session: { user_id: @admin_user.id }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(io_mappings_path(io_interface_id: @io_interface.id))
      expect(flash[:success]).to be_present
      expect(mapping.reload.position).to eq earlier_position
      expect(earlier.reload.position).to eq mapping_position
      expect(other.reload.position).to eq other_position
    end
  end

  describe '#move_down' do
    it 'swaps position with the next mapping on the same interface and redirects' do
      first = create(:io_mapping, meta_key: @meta_key, io_interface: @io_interface)
      other_interface = create(:io_interface)
      other = create(:io_mapping, meta_key: @meta_key, io_interface: other_interface)
      later = create(:io_mapping, meta_key: @meta_key, io_interface: @io_interface)
      first_position = first.position
      later_position = later.position
      other_position = other.position

      patch :move_down,
            params: { id: first.id },
            session: { user_id: @admin_user.id }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(io_mappings_path(io_interface_id: @io_interface.id))
      expect(flash[:success]).to be_present
      expect(first.reload.position).to eq later_position
      expect(later.reload.position).to eq first_position
      expect(other.reload.position).to eq other_position
    end
  end

  context 'moving within one interface' do
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

    it '#move_to_top moves the mapping to the first position of its interface' do
      move(:to_top, @m3)
      expect(order_of(@io_interface)).to eq [@m3, @m1, @m2].map(&:id)
      expect(order_of(@other_interface)).to eq [@o1, @o2].map(&:id)
    end

    it '#move_to_bottom moves the mapping to the last position of its interface' do
      move(:to_bottom, @m1)
      expect(order_of(@io_interface)).to eq [@m2, @m3, @m1].map(&:id)
      expect(order_of(@other_interface)).to eq [@o1, @o2].map(&:id)
    end

    it '#move_up on the first mapping does not change the order' do
      move(:up, @m1)
      expect(order_of(@io_interface)).to eq [@m1, @m2, @m3].map(&:id)
    end

    it '#move_down on the last mapping does not change the order' do
      move(:down, @m3)
      expect(order_of(@io_interface)).to eq [@m1, @m2, @m3].map(&:id)
    end

    it 'keeps interface and page in the redirect' do
      move(:up, @m2, page: '2')
      expect(response).to redirect_to(
        io_mappings_path(io_interface_id: @io_interface.id, page: '2'))
    end

    it '#move_to_top on the first mapping does not change the order' do
      move(:to_top, @m1)
      expect(order_of(@io_interface)).to eq [@m1, @m2, @m3].map(&:id)
    end

    it '#move_to_bottom on the last mapping does not change the order' do
      move(:to_bottom, @m3)
      expect(order_of(@io_interface)).to eq [@m1, @m2, @m3].map(&:id)
    end

    it 'a sequence of moves keeps positions gapless per interface' do
      move(:down, @m1)
      move(:to_top, @m3)
      move(:up, @m1)
      move(:to_bottom, @m3)
      expect(order_of(@io_interface)).to eq [@m1, @m2, @m3].map(&:id)
      expect(IoMapping.where(io_interface: @io_interface).reorder(:position).pluck(:position))
        .to eq [0, 1, 2]
      expect(order_of(@other_interface)).to eq [@o1, @o2].map(&:id)
    end

    %i(up down to_top to_bottom).each do |direction|
      it "#move_#{direction} redirects to the interface list with a success flash" do
        move(direction, @m2)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(io_mappings_path(io_interface_id: @io_interface.id))
        expect(flash[:success]).to be_present
      end

      it "#move_#{direction} does not change the other interface" do
        move(direction, @m2)
        expect(order_of(@other_interface)).to eq [@o1, @o2].map(&:id)
      end

      it "#move_#{direction} renders 404 for an unknown mapping" do
        patch "move_#{direction}",
              params: { id: SecureRandom.uuid },
              session: { user_id: @admin_user.id }
        expect(response).to have_http_status(404)
        expect(response).to render_template 'errors/404'
      end
    end
  end
end
