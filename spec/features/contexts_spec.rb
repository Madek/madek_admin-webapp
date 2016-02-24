require 'spec_helper'
require 'spec_helper_feature'

feature 'Admin Contexts' do
  let!(:context) { create :context_with_context_keys }

  scenario 'Editing a context' do
    visit contexts_path

    within "[data-id='#{context.id}']" do
      click_link 'Edit'
    end

    expect(current_path).to eq edit_context_path(context)

    fill_in 'context[label]', with: 'new label'
    fill_in 'context[description]', with: 'new description'
    fill_in 'context[admin_comment]', with: 'new admin comment'

    click_button 'Save'

    expect(current_path).to eq context_path(context)
    expect(page).to have_content 'Label new label'
    expect(page).to have_content 'Description new description'
    expect(page).to have_content 'Admin comment new admin comment'
  end

  scenario 'Displaying details' do
    visit context_path(context)

    expect(page).to have_content "Id #{context.id}"
    expect(page).to have_content "Label #{context.label}"
    expect(page).to have_content "Description #{context.description}"
    expect(page).to have_content "Admin comment #{context.admin_comment}"
  end
end
