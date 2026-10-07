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

  scenario 'moving mappings while a search term is set' do
    core_mappings = %w(core_d core_e).map do |key_map|
      create(:io_mapping, io_interface: interface, meta_key: mappings[0].meta_key,
                          key_map: key_map)
    end
    create(:io_mapping, io_interface: other_interface, meta_key: mappings[0].meta_key,
                        key_map: 'core_z')

    visit io_mappings_path
    select 'order_test', from: 'io_interface_id'
    fill_in 'search_term', with: 'core'
    click_on 'Apply'
    expect_order %w(core_d core_e)
    expect_move_buttons(count: 2)
    expect(page).not_to have_css('.reorder-hint')

    within("tr[data-id='#{core_mappings[1].id}']") { find('.move-up').click }
    expect(page).to have_css('.alert-success')
    expect(page).to have_select('io_interface_id', selected: 'order_test')
    expect(page).to have_field('search_term', with: 'core')
    expect_order %w(core_e core_d)

    within("tr[data-id='#{core_mappings[1].id}']") { find('.move-down').click }
    expect_order %w(core_d core_e)

    within("tr[data-id='#{core_mappings[1].id}']") { find('.move-to-top').click }
    expect_order %w(core_e core_d)

    visit io_mappings_path(io_interface_id: interface.id)
    expect_order %w(core_e key_a key_b key_c core_d)

    visit io_mappings_path(io_interface_id: other_interface.id)
    expect_order %w(key_x key_y core_z)
  end

  scenario 'no move buttons after switching back to all interfaces' do
    visit io_mappings_path(io_interface_id: interface.id)
    expect_move_buttons(count: 3)
    expect(page).not_to have_css('.reorder-hint')

    select 'All IO interfaces', from: 'io_interface_id'
    click_on 'Apply'

    expect(page).to have_field('io_interface_id', with: '')
    expect(page).to have_css('h1', text: "IO Mappings (#{IoMapping.count})")
    expect_move_buttons(count: 0)
    expect(page).to have_css('.reorder-hint')
  end

  def expect_move_buttons(count:)
    %w(.move-to-top .move-up .move-down .move-to-bottom).each do |css|
      expect(page).to have_css(css, count: count)
    end
  end

  def expect_order(key_maps)
    expect(all('table tbody tr[data-id] td:nth-child(3)').map(&:text)).to eq key_maps
  end
end
