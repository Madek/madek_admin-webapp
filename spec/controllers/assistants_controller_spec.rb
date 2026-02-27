require "spec_helper"

describe AssistantsController do
  let(:admin_user) { create(:admin_user) }

  describe "#sql_reports" do
    render_views

    it "returns entries missing at least one required metakey" do
      allow(controller).to receive(:feature_toggle_sql_reports).and_return(true)

      app_setting = AppSetting.first || create(:app_setting)
      context = create(:context, id: "required_for_query_spec")

      title_meta_key = MetaKey.find_by(id: "madek_core:title") \
        || create(:meta_key_text, id: "madek_core:title")
      copyright_meta_key = MetaKey.find_by(id: "madek_core:copyright_notice") \
        || create(:meta_key_text, id: "madek_core:copyright_notice")

      create(:context_key,
        context: context,
        meta_key: title_meta_key,
        is_required: true)
      create(:context_key,
        context: context,
        meta_key: copyright_meta_key,
        is_required: true)

      complete_responsible = create(:user)
      title_only_responsible = create(:user)
      missing_all_responsible = create(:user)

      complete_entry = create(:media_entry, is_published: true, responsible_user: complete_responsible)
      title_only_entry = create(:media_entry, is_published: true, responsible_user: title_only_responsible)
      create(:media_entry, is_published: true, responsible_user: missing_all_responsible)

      create(:meta_datum_text,
        media_entry: complete_entry,
        meta_key: title_meta_key,
        string: "Complete title")
      create(:meta_datum_text,
        media_entry: complete_entry,
        meta_key: copyright_meta_key,
        string: "Complete copyright")

      create(:meta_datum_text,
        media_entry: title_only_entry,
        meta_key: title_meta_key,
        string: "Only title")

      # media_entry factory resets this setting during creation, so apply it here.
      app_setting.update!(contexts_for_entry_validation: [context.id])

      get :sql_reports, params: {
        query: find_invalid_entries_query,
        run: "Run Query"
      }, session: {
        user_id: admin_user.id
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(title_only_responsible.id)
      expect(response.body).to include(missing_all_responsible.id)
      expect(response.body).not_to include(complete_responsible.id)
    end
  end

  def find_invalid_entries_query
    YAML.load_file(Rails.root.join("config", "sql_snippets.yml"))
      .fetch("sql_snippets")
      .find { |snippet| snippet.fetch("title") == "Find Invalid Entries" }
      .fetch("query")
  end
end
