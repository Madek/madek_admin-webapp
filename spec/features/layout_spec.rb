require 'spec_helper'
require 'spec_helper_feature'

feature 'Layout' do
  scenario 'Navbar contains link to /my' do
    visit root_path

    within '.navbar' do
      expect(page).to have_link 'Home/My', href: '/my'
    end
  end
end
