module WebappPathHelpers
  extend ActiveSupport::Concern

  included do
    helper_method :ui_group_path
    def ui_group_path(group)
      "/my/groups/#{group.id}"
    end

    helper_method :ui_entry_path
    def ui_entry_path(entry)
      "/entries/#{entry.id}"
    end

    helper_method :ui_person_path
    def ui_person_path(person)
      "/people/#{person.id}"
    end

    helper_method :ui_collection_path
    def ui_collection_path(collection)
      "/sets/#{collection.id}"
    end
  end
end
