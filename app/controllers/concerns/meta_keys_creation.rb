module Concerns
  module MetaKeysCreation
    extend ActiveSupport::Concern

    def new
      @meta_key = MetaKey.new
    end

    def create
      attr = meta_key_params.deep_symbolize_keys

      # if vocabulary prefix wasn't given, we can just infer it:
      unless attr[:id].include?(':')
        attr[:id] = "#{attr[:vocabulary_id]}:#{attr[:id]}"
      end

      @meta_key = MetaKey.new(attr)

      if second_step?
        second_step_columns
        flash[:info] = second_step_flash
        render :new
      else
        @meta_key.save!
        respond_with @meta_key, location: (lambda do
          edit_meta_key_path(@meta_key)
        end)
      end
    end

    private

    def second_step?
      @meta_key.meta_datum_object_type_changed? &&
        second_step_columns &&
          second_step_columns.none? do |column|
            params[:meta_key].key?(column)
          end
    end

    def second_step_columns
      @second_step_columns ||= {
        'MetaDatum::People' => [:allowed_people_subtypes],
        'MetaDatum::Keywords' => [
          :is_extensible_list, :keywords_alphabetical_order
        ],
        'MetaDatum::Text' => [:text_type]
      }[@meta_key.meta_datum_object_type]
    end

    def second_step_flash
      @second_step_columns.map do |column|
        I18n.t(column, scope: :second_step_flash)
      end.join(' ')
    end

  end
end
