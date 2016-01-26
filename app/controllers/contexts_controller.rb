class Admin::ContextsController < AdminController
  def index
    @contexts = Context.all
  end

  def show
    @context = Context.find(params[:id])
    @context_keys =
      @context.context_keys
  end
end
