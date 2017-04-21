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
          path: media_entries_url(filter: { is_published: 0 })
        },
        {
          title: 'entries',
          model: MediaEntry
        },
        {
          title: 'sets',
          model: Collection
        },
        FilterSet
      ],
      [
        Vocabulary,
        MetaKey,
        Context
      ],
      [
        MediaFile,
        {
          title: 'metadata',
          model: MetaDatum,
          path: meta_datums_url
        },
        Keyword,
        Person
      ],
      [
        User,
        Group,
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
      item[:path]  ||= url_for(item[:model])
      item.except(:model, :scope)
    elsif item.is_a?(Class)
      {
        title: title(item),
        counter: item.count,
        path: url_for(item)
      }
    end
  end

  def title(model_name)
    model_name.to_s.pluralize.downcase
  end

end
