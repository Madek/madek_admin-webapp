# A few global functions shared between all rspec feature tests.
#
# * Keep this file lexically sorted.
#
# * Keep this file small and simple.
#
# * Only simple functions shall be included.
#
# * Only general functions shall be included.
#
# Favor clearness, and simplicity instead of dryness!
#

def click_on_tab(text)
  find('.app-body .ui-tabs').find('a', text: text).click
end

def find_input_with_name(name)
  find("textarea,input[name='#{name}']")
end
