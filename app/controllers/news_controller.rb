# frozen_string_literal: true
class NewsController < ApplicationController
  before_action :login_required, except: [:index, :show]
  before_action :require_staff, except: [:index, :show]
  before_action :find_news, only: [:show, :edit, :update, :destroy]
  before_action :require_permission, only: [:edit, :update]

  def index
    @page_title = 'Site News'
    @news = News.order(id: :desc).paginate(page: page, per_page: 1)
    @news.first&.mark_read(current_user) if logged_in?
  end

  def new
    @page_title = 'Create News Post'
    @news = News.new
  end

  def create
    @news = News.new(news_params)
    @news.user = current_user

    unless @news.save
      flash.now[:error] = {}
      flash.now[:error][:message] = "News post could not be created."
      flash.now[:error][:array] = @news.errors.full_messages
      @page_title = 'Create News Post'
      render :new and return
    end

    flash[:success] = "News post has successfully been created."
    redirect_to news_index_path
  end

  def show
    redirect_to paged_news_url(@news)
  end

  def edit
    @page_title = 'Edit News Post'
  end

  def update
    unless @news.update(news_params)
      flash.now[:error] = {}
      flash.now[:error][:message] = "News post could not be saved because of the following problems:"
      flash.now[:error][:array] = @news.errors.full_messages
      @page_title = "Edit News Post"
      render :edit and return
    end

    flash[:success] = "News post saved!"
    redirect_to paged_news_url(@news)
  end

  def destroy
    unless @news.deletable_by?(current_user)
      flash[:error] = "You do not have permission to edit that news post."
      redirect_to news_index_path and return
    end

    begin
      @news.destroy!
      flash[:success] = "News post deleted."
    rescue ActiveRecord::RecordNotDestroyed
      flash[:error] = {}
      flash[:error][:message] = "News post could not be deleted."
      flash[:error][:array] = @news.errors.full_messages
    end
    redirect_to news_index_path
  end

  private

  def find_news
    unless (@news = News.find_by_id(params[:id]))
      flash[:error] = "News post could not be found."
      redirect_to news_index_path and return
    end
  end

  def require_staff
    unless current_user.admin? || current_user.mod?
      flash[:error] = "You do not have permission to manage news posts."
      redirect_to news_index_path and return
    end
  end

  def require_permission
    unless @news.editable_by?(current_user)
      flash[:error] = "You do not have permission to edit that news post."
      redirect_to news_index_path and return
    end
  end

  def news_params
    params.fetch(:news, {}).permit(:content)
  end

  def paged_news_url(news)
    page_num = News.where('id >= ?', news.id).count
    page_num = nil unless page_num > 1
    news_index_path(page: page_num)
  end
end
