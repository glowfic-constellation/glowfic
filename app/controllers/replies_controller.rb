class RepliesController < ApplicationController
  before_filter :login_required
  before_filter :build_template_groups, only: :edit
  before_filter :find_reply, only: [:edit, :update, :destroy]

  def create
    reply = Reply.new(params[:reply])
    reply.user = current_user
    if reply.save
      flash[:success] = "Posted!"
      redirect_to reply_link(reply)
    else
      flash[:error] = "Problems. "+reply.errors.full_messages.to_s
      redirect_to post_path(reply.post)
    end
  end

  def edit
    @character = @reply.character
    @image = @reply.icon
    use_javascript('posts')
  end

  def update
    @reply.update_attributes(params[:reply])
    flash[:success] = "Post updated"
    redirect_to reply_link(@reply)
  end

  def destroy
    @reply.destroy
    flash[:success] = "Post deleted."
    redirect_to post_path(@reply.post)
  end

  private

  def find_reply
    @reply = Reply.find_by_id(params[:id])

    unless @reply
      flash[:error] = "Post could not be found."
      redirect_to boards_path and return
    end
  end

  def build_template_groups
    return unless logged_in?

    templates = current_user.templates.sort_by(&:name)
    faked = Struct.new(:name, :id, :ordered_characters)
    templateless = faked.new('Templateless', nil, current_user.characters.where(:template_id => nil).to_a)
    @templates = templates + [templateless]

    gon.current_user = current_user.gon_attributes
    gon.character_path = character_user_path(current_user)
  end

  def reply_link(reply)
    per = per_page > 0 ? per_page : reply.post.replies.count
    array = reply.post.replies.select(:id).map(&:id)
    hash = Hash[array.map.with_index.to_a]
    reply_index = hash[reply.id]
    page = (reply_index / per) + 1
    dict = {anchor: "reply-#{reply.id}"}
    dict['page'] = page if page > 1
    dict['per_page'] = params[:per_page] if params[:per_page]
    post_path(reply.post, dict)
  end
end
