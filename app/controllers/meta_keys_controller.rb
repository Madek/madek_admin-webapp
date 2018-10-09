class MetaKeysController < ApplicationController
  include Concerns::MetaKeysCreation
  include Concerns::MetaKeysMoving
  include Concerns::LocalizedFieldParams

  def index
    @meta_keys = MetaKey.with_keywords_count
                        .includes(:context_keys)
                        .page(params[:page])
                        .per(16)

    remember_context_id
    @context = get_context_from_session

    filter_and_sort
  end

  def show
    @meta_key = MetaKey.includes(:context_keys)
                       .find(params[:id])
    unless @meta_key.is_extensible_list
      @keyword = Keyword.new(
        meta_key_id: @meta_key.id
      )
    end
    @keywords = @meta_key.keywords.page(params[:page]).per(16)
    @roles = @meta_key.roles.sorted.page(params[:page]).per(16)
    @usage_counts = Keyword.usage_count_for(@keywords)
  end

  def edit
    @meta_key = MetaKey.find(params[:id])
    authorize @meta_key
  end

  def update
    @meta_key = MetaKey.find(params[:id])
    authorize @meta_key
    @meta_key.assign_attributes(meta_key_params)

    if second_step?
      second_step_columns
      flash[:info] = second_step_flash
      render :edit
    else
      @meta_key.save!
      respond_with @meta_key, location: (lambda do
        meta_key_path(@meta_key)
      end)
    end
  end

  define_destroy_action_for(MetaKey, true)

  define_move_actions_for(MetaKey, true) do |meta_key|
    edit_vocabulary_path(meta_key.vocabulary)
  end

  private

  def filter_and_sort
    if @context.present?
      filter_not_in_context(@context)
    end
    if (search_term = params[:search_term]).present?
      filter_by_term(search_term)
    end
    if (vocabulary_id = params[:vocabulary_id]).present?
      filter_by_vocabulary(vocabulary_id)
    end
    if (type = params[:type]).present?
      filter_by_type(type)
    end
    sort
  end

  def filter_not_in_context(context)
    @meta_keys = @meta_keys.not_in_context(context)
  end

  def filter_by_term(term)
    @meta_keys = @meta_keys.filter_by(term)
  end

  def filter_by_type(type)
    @meta_keys = @meta_keys.with_type(type)
  end

  def filter_by_vocabulary(id)
    @meta_keys = @meta_keys.of_vocabulary(id)
  end

  def meta_key_params
    params
      .require(:meta_key)
      .permit(
        :id,
        :meta_datum_object_type,
        :text_type,
        :is_extensible_list,
        :keywords_alphabetical_order,
        :vocabulary_id,
        :is_enabled_for_media_entries,
        :is_enabled_for_collections,
        :allowed_rdf_class,
        {
          allowed_people_subtypes: []
        }.merge(localized_field_params_for(MetaKey))
      )
  end

  def sort
    if params[:sort_by] == 'name_part'
      @meta_keys = @meta_keys.order_by_name_part
    end
  end

  def remember_context_id
    if params[:context_id].present?
      session[:context_id] = params[:context_id]
    end
  end

  def get_context_from_session
    Context.find(session[:context_id]) if session[:context_id].present?
  end

end
