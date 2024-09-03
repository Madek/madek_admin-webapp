class ContextKeysController < ApplicationController
  include LocalizedFieldParams

  def edit
    @context_key = ContextKey.find(params[:id])
  end

  def update
    @context_key = ContextKey.find(params[:id])
    @context_key.assign_attributes(context_key_params)
    @context_key.save!

    respond_with @context_key, location: (lambda do
      context_path(@context_key.context)
    end)
  end

  define_move_actions_for(ContextKey) do |context_key|
    edit_context_path(context_key.context)
  end

  def destroy
    @context_key = ContextKey.find(params[:id])
    @context_key.destroy!

    respond_with @context_key.meta_key, location: (lambda do
      edit_context_path(@context_key.context)
    end)
  end

  private

  def context_key_params
    params
      .require(:context_key)
      .permit(:is_required,
              :length_min,
              :length_max,
              :admin_comment,
              localized_field_params)
  end
end
