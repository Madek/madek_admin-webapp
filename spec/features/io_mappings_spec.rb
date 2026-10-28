require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin IO Mappings ordering' do
  let(:interface) { create(:io_interface, id: 'order_test') }
  let(:other_interface) { create(:io_interface, id: 'order_other') }
  let!(:mappings) do
    %w(a b c).map do |suffix|
      meta_key = create(:meta_key_text, id: "test:madek_order_#{suffix}")
      create(:io_mapping, io_interface: interface, meta_key: meta_key,
                          key_map: "key_#{suffix}")
    end
  end
  let!(:other_mappings) do
    %w(x y).map do |suffix|
      meta_key = create(:meta_key_text, id: "test:other_order_#{suffix}")
      create(:io_mapping, io_interface: other_interface, meta_key: meta_key,
                          key_map: "key_#{suffix}")
    end
  end

  scenario 'moving mappings changes the visible order of one interface' do
    visit io_mappings_path
    select 'order_test', from: 'io_interface_id'
    click_on 'Apply'
    expect_order %w(key_a key_b key_c)

    within("tr[data-id='#{mappings[0].id}']") { find('.move-down').click }
    expect(page).to have_css('.alert-success')
    expect(page).to have_select('io_interface_id', selected: 'order_test')
    expect_order %w(key_b key_a key_c)

    within("tr[data-id='#{mappings[2].id}']") { find('.move-up').click }
    expect_order %w(key_b key_c key_a)

    within("tr[data-id='#{mappings[0].id}']") { find('.move-to-top').click }
    expect_order %w(key_a key_b key_c)

    within("tr[data-id='#{mappings[0].id}']") { find('.move-to-bottom').click }
    expect_order %w(key_b key_c key_a)

    visit io_mappings_path(io_interface_id: other_interface.id)
    expect_order %w(key_x key_y)
  end

  scenario 'the interface filter is kept when searching' do
    visit io_mappings_path(io_interface_id: interface.id)
    fill_in 'search_term', with: 'order'
    click_on 'Apply'

    expect(page).to have_select('io_interface_id', selected: 'order_test')
    expect_order %w(key_a key_b key_c)
  end

  scenario 'no move buttons while a search term is set' do
    visit io_mappings_path(io_interface_id: interface.id, search_term: 'madek')

    expect_order %w(key_a key_b key_c)
    expect(page).not_to have_css('.move-up')
    expect(page).to have_css('.reorder-hint')
  end

  scenario 'no move buttons without an interface' do
    visit io_mappings_path

    expect(page).not_to have_css('.move-up')
    expect(page).to have_css('.reorder-hint')
  end

  def expect_order(key_maps)
    expect(all('table tbody tr[data-id] td:nth-child(3)').map(&:text)).to eq key_maps
  end
end
