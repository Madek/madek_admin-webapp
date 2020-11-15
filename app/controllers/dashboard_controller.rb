class DashboardController < ApplicationController

  include Concerns::AppEnvironmentInfo

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
          path: media_entries_path(filter: { is_published: 0 })
        },
        {
          title: 'entries',
          model: MediaEntry
        },
        {
          title: 'sets',
          model: Collection
        }
      ],
      [
        MediaFile,
        {
          title: 'metadata',
          model: MetaDatum,
          path: meta_datums_path
        },
        Keyword,
        Person
      ],
      [
        Vocabulary,
        MetaKey,
        Context,
        Role
      ],
      [
        User,
        Group,
        Delegation,
        {
          title: 'api-clients',
          model: ApiClient
        }
      ]
    ].map { |row| row.map(&method(:app_resource_data_item)) }
  end
  # rubocop:enable Metrics/MethodLength

  def app_resource_data_item(item)
    if item.is_a?(Hash)
      item[:counter] =
        if item.key?(:scope)
          item[:scope].call.count
        else
          item[:model].count
        end
      item[:title] ||= title(item[:model])
      item[:path]  ||= app_resource_path(item[:model])
      item.except(:model, :scope)
    elsif item.is_a?(Class)
      {
        title: title(item),
        counter: item.count,
        path: app_resource_path(item)
      }
    end
  end

  def app_resource_path(model)
    url_for(controller: model.name.tableize, action: :index, only_path: true)
  end

  def title(model_name)
    model_name.to_s.pluralize.downcase
  end

end
