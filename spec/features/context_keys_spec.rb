require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin Context Keys' do
  let(:context) { Context.find('upload') }
  let(:context_key) { context.context_keys.first }

  scenario 'Editing Context via Edit button' do
    visit context_path(context)

    within "[data-id='#{context_key.id}']" do
      click_link 'Edit'
    end

    expect(current_path).to eq edit_context_key_path(context_key)

    fill_in 'context_key[label]', with: 'new label'
    fill_in 'context_key[description]', with: 'newdescription'
    fill_in 'context_key[hint]', with: 'new hint'
    expect(page).to have_checked_field 'context_key[is_required]'
    uncheck 'context_key[is_required]'
    fill_in 'context_key[length_min]', with: 16
    fill_in 'context_key[length_max]', with: 128
    expect(page).to have_select('context_key[text_element]', selected: [])
    select 'input', from: 'context_key[text_element]'
    fill_in 'context_key[admin_comment]', with: 'new admin comment'

    click_button 'Save'
    expect(current_path).to eq context_path(context)
    expect(page).to have_css('.alert-success')

    within "[data-id='#{context_key.id}']" do
      click_link 'Edit'
    end

    expect(page).to have_field 'context_key[label]', with: 'new label'
    expect(page).to have_field 'context_key[description]', with: 'newdescription'
    expect(page).to have_field 'context_key[hint]', with: 'new hint'
    expect(page).to have_unchecked_field 'context_key[is_required]'
    expect(page).to have_field 'context_key[length_min]', with: 16
    expect(page).to have_field 'context_key[length_max]', with: 128
    expect(page).to have_select 'context_key[text_element]', selected: 'input'
    expect(page).to have_field('context_key[admin_comment]',
                               with: 'new admin comment')
  end

  scenario 'Changing position in scope of a context' do
    visit edit_context_path(context)
    expect_order %w(madek_core:title
                    madek_core:authors
                    madek_core:portrayed_object_date
                    madek_core:keywords)

    within('table tr:contains("madek_core:authors")') do
      find('.move-down').click
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(madek_core:title
                    madek_core:portrayed_object_date
                    madek_core:authors
                    madek_core:keywords)

    within('table tr:contains("madek_core:portrayed_object_date")') do
      find('.move-up').click
    end
    expect(page).to have_css('.alert-success')

    expect_order %w(madek_core:portrayed_object_date
                    madek_core:title
                    madek_core:authors
                    madek_core:keywords)
  end

  def expect_order(order, limit = 4)
    expect(
      all('table.edit-context-keys tr[data-id] samp a').map(&:text)[0, limit]
    ).to eq(order)
  end
end
