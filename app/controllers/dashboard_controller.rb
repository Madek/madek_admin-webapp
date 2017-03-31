class DashboardController < ApplicationController

  def index
    @data = prepare_data
  end

  private

  # rubocop:disable Metrics/MethodLength
  def prepare_data
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
      FilterSet,
      MediaFile,
      {
        title: 'metadata',
        model: MetaDatum,
        path: meta_datums_url
      },
      Keyword,
      Person,
      Vocabulary,
      MetaKey,
      Context,
      User,
      Group,
      {
        title: 'api-clients',
        model: ApiClient
      }
    ].map { |item| data_item(item) }
  end
  # rubocop:enable Metrics/MethodLength

  def data_item(item)
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
