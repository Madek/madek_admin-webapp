class DashboardController < ApplicationController
  self.admin_permission_key = :any

  include AppEnvironmentInfo

  def index
    env_info = Rails.cache.fetch('app_environment_info', expires_in: 10.minutes) do
      app_environment_info
    end

    @data = {
      resources: app_resources_info,
      environment: env_info
    }
  end

  def refresh
    Rails.cache.delete 'app_environment_info'
    redirect_to root_path
  end

  private

  # rubocop:disable Metrics/MethodLength
  def app_resources_info
    [
      [
        {
          title: 'drafts',
          model: MediaEntry,
          scope: -> { MediaEntry.unscoped.not_published },
          path: media_entries_path(filter: { is_published: 0 }),
          permission_key: 'entries'
        },
        { title: 'entries', model: MediaEntry, permission_key: 'entries' },
        { title: 'sets', model: Collection, permission_key: 'sets' }
      ],
      [
        { model: MediaFile, permission_key: 'entries' },
        { title: 'metadata', model: MetaDatum, path: meta_datums_path, permission_key: 'meta_data' },
        { model: Keyword, permission_key: 'keywords' }
      ],
      [
        { model: Person, permission_key: 'people' },
        { model: RolesList, permission_key: 'roles' },
        { model: Role, permission_key: 'roles' }
      ],
      [
        { model: Vocabulary, permission_key: 'vocabularies' },
        { model: MetaKey, permission_key: 'meta_data' },
        { model: Context, permission_key: 'contexts' }
      ],
      [
        { model: User, permission_key: 'users' },
        { model: Group, permission_key: 'groups' },
        { model: Delegation, permission_key: 'delegations' },
        { title: 'api-clients', model: ApiClient, permission_key: 'api_clients' }
      ]
    ].map { |row| row.select { |item| current_user.has_admin_permission?(item[:permission_key]) } }
     .reject(&:empty?)
     .map { |row| row.map(&method(:app_resource_data_item)) }
  end
  # rubocop:enable Metrics/MethodLength

  def app_resource_data_item(item)
    item[:counter] =
      if item.key?(:scope)
        item[:scope].call.count
      else
        item[:model].count
      end
    item[:title] ||= title(item[:model])
    item[:path]  ||= app_resource_path(item[:model])
    item.except(:model, :scope, :permission_key)
  end

  def app_resource_path(model)
    url_for(controller: model.name.tableize, action: :index, only_path: true)
  end

  def title(model_name)
    model_name.to_s.pluralize.downcase
  end

end
