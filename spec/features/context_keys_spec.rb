require 'spec_helper'
require 'spec_helper_feature'
require_relative 'shared/admin_comments'

feature 'Admin Context Keys' do
  let(:context) { Context.find('upload') }
  let(:context_key) { context.context_keys.first }
  let(:collection_path) { context_path(context) }

  scenario 'Editing ContextKey via Edit button' do
    visit collection_path

    within "[data-id='#{context_key.id}']" do
      click_link 'Edit'
    end

    expect(current_path).to eq edit_context_key_path(context_key)

    fill_in 'context_key[labels][de]', with: 'new label DE'
    fill_in 'context_key[labels][en]', with: 'new label EN'
    fill_in 'context_key[descriptions][de]', with: 'new desc DE'
    fill_in 'context_key[descriptions][en]', with: 'new desc EN'
    fill_in 'context_key[hints][de]', with: 'new hint DE'
    fill_in 'context_key[hints][en]', with: 'new hint EN'
    expect(page).to have_checked_field 'context_key[is_required]'
    uncheck 'context_key[is_required]'
    fill_in 'context_key[length_min]', with: 16
    fill_in 'context_key[length_max]', with: 128
    fill_in 'context_key[admin_comment]', with: 'new admin comment'

    click_button 'Save'
    expect(current_path).to eq collection_path
    expect(page).to have_css('.alert-success')

    within "[data-id='#{context_key.id}']" do
      click_link 'Edit'
    end

    expect(page).to have_field 'context_key[labels][de]', with: 'new label DE'
    expect(page).to have_field 'context_key[labels][en]', with: 'new label EN'
    expect(page).to have_field 'context_key[descriptions][de]', with: 'new desc DE'
    expect(page).to have_field 'context_key[descriptions][en]', with: 'new desc EN'
    expect(page).to have_field 'context_key[hints][de]', with: 'new hint DE'
    expect(page).to have_field 'context_key[hints][en]', with: 'new hint EN'
    expect(page).to have_unchecked_field 'context_key[is_required]'
    expect(page).to have_field 'context_key[length_min]', with: 16
    expect(page).to have_field 'context_key[length_max]', with: 128
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

    within('table tr:contains("madek_core:authors")') do
      find('.move-to-top').click
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(madek_core:authors
                    madek_core:portrayed_object_date
                    madek_core:title
                    madek_core:keywords)

    within('table tr:contains("madek_core:authors")') do
      find('.move-to-top').click
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(madek_core:authors
                    madek_core:portrayed_object_date
                    madek_core:title
                    madek_core:keywords)

    within('table tr:contains("madek_core:portrayed_object_date")') do
      find('.move-to-bottom').click
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(madek_core:authors
                    madek_core:title
                    madek_core:keywords
                    madek_core:copyright_notice
                    copyright:license
                    copyright:copyright_usage
                    copyright:copyright_url
                    madek_core:portrayed_object_date), 8

    within('table tr:contains("madek_core:portrayed_object_date")') do
      find('.move-to-bottom').click
    end
    expect(page).to have_css('.alert-success')
    expect_order %w(madek_core:authors
                    madek_core:title
                    madek_core:keywords
                    madek_core:copyright_notice
                    copyright:license
                    copyright:copyright_usage
                    copyright:copyright_url
                    madek_core:portrayed_object_date), 8
  end

  include_examples 'display admin comments on overview page'

  def expect_order(order, limit = 4)
    expect(
      all('table.edit-context-keys tr[data-id] samp a').map(&:text)[0, limit]
    ).to eq(order)
  end
end
