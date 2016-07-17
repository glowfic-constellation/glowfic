class TagsController < ApplicationController
  before_filter :login_required, except: [:index, :show]
  before_filter :find_tag, except: [:index, :new, :create]
  before_filter :permission_required, only: [:edit, :update, :destroy]

  def index
    respond_to do |format|
      format.json do
        render json: {results: TagService.search(params[:t], params[:q])}
      end
      format.html do
        @page_title = "Tags"
      end
    end
  end

  def new
    @tag = Tag.new
    @page_title = "New Tag"
  end

  def create
    @tag = Tag.new(params[:tag])
    @tag.user = current_user

    unless save_model(@tag)
      @page_title = "New Tag"
      render action: :new and return
    end

    flash[:success] = "Tag created!"
    redirect_to tag_path(@tag)
  end

  def show
    @posts = @tag.posts.paginate(per_page: 25, page: page)
    @page_title = "#{@tag.name}"
  end

  def edit
    @page_title = "Edit Tag #{@tag.name}"
  end

  def update
    @tag.assign_attributes(params[:tag])
    unless save_model(@tag)
      @page_title = "Edit Tag #{@tag.name}"
      render action: :edit and return
    end

    flash[:success] = "Tag saved!"
    redirect_to tag_path(@tag)
  end

  def destroy
    @tag.destroy
    flash[:success] = "Tag deleted."
    redirect_to tags_path
  end

  private

  def find_tag
    unless @tag = Tag.find_by_id(params[:id])
      flash[:error] = "Tag could not be found."
      redirect_to tags_path
    end
  end

  def permission_required
    unless @tag.editable_by?(current_user)
      flash[:error] = "You do not have permission to edit this tag."
      redirect_to tag_path(@tag)
    end
  end
end
