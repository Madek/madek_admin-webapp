class ContextsController < ApplicationController
  include Concerns::LocalizedFieldParams

  def index
    @contexts = Context.all
    @app_settings = AppSetting.first
  end

  def show
    @app_settings = AppSetting.first
    @context = Context.find(params[:id])
  end

  def edit
    @context = Context.find(params[:id])

    if params[:forget_context_id].present?
      session[:context_id] = nil
    end
  end

  def update
    @context = Context.find(params[:id])
    @context.update! context_params

    respond_with @context
  end

  def new
    @params = new_context_params
    @duplicated_from = get_duplicated_from(@params)

    if @duplicated_from
      admin_comment = "Duplicated from #{@duplicated_from.class.name} " \
        "'#{@duplicated_from.label}' (#{@duplicated_from.id}) " \
        "at #{Time.now.utc}"
      if @duplicated_from.admin_comment
        admin_comment += \
          ", #{"previous comment was:\n---\n#{@duplicated_from.admin_comment}"}"
      end
      prefilled_attrs = {
        id: @duplicated_from.id + '_copy',
        labels: @duplicated_from.labels,
        descriptions: @duplicated_from.descriptions,
        admin_comment: admin_comment
      }
    end

    @context = Context.new(prefilled_attrs)
  end

  def create
    ActiveRecord::Base.transaction do
      @context = Context.new(create_context_params)
      if (duplicate_from = get_duplicated_from(new_context_params))
        duplicate_keys(@context, duplicate_from)
      end
      @context.save!
    end
    respond_with @context, location: -> { context_path(@context) }
  end

  def destroy
    context = Context.find(params[:id])
    context.destroy!

    respond_with context
  end

  def add_meta_key
    context = Context.find(params[:id])
    create_context_key_for(context)
    session[:context_id] = nil

    redirect_to edit_context_path(context), flash: {
      success: 'The Meta Key was successfully added to the Context.'
    }
  end

  private

  def context_params
    params
      .require(:context)
      .permit(
        :admin_comment,
        localized_field_params)
  end

  def new_context_params
    params.permit(:from_context, :from_vocabulary)
  end

  def create_context_params
    params.require(:context).permit(:id,
                                    :admin_comment,
                                    :from_context,
                                    :from_vocabulary,
                                    localized_field_params)
  end

  def create_context_key_for(context)
    ContextKey.create!(
      context: context,
      meta_key: MetaKey.find(params[:meta_key_id])
    )
  end

  def get_duplicated_from(params)
    if params[:from_context].present?
      Context.find(params[:from_context])
    elsif params[:from_vocabulary].present?
      Vocabulary.find(params[:from_vocabulary])
    end
  end

  def duplicate_keys(new_context, duplicate_from)
    ckeys = if duplicate_from.is_a?(Context)
              duplicate_from.context_keys.map(&:attributes)
            else
              duplicate_from.meta_keys.map do |mk|
                dont_overide = { labels: {}, descriptions: {}, admin_comment: nil }
                mk.attributes.slice(*ContextKey.attribute_names)
                  .merge(meta_key_id: mk.id).merge(dont_overide)
              end
            end
    ckeys.each do |attrs|
      ContextKey.create!(attrs.merge(id: nil, context: new_context))
    end
  end

end
