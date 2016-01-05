class MessagesController < ApplicationController
  before_filter :login_required

  def index
    if params[:view] == 'outbox'
      @view = 'outbox'
      @page_title = "Outbox"
      @messages = current_user.sent_messages.where(visible_outbox: true).order('id desc')
    else
      @view = 'inbox'
      @page_title = "Inbox"
      @messages = current_user.messages.where(visible_inbox: true).order('id desc')
    end
  end

  def new
    use_javascript('messages')
    @message = Message.new
    @page_title = "Compose Message"
    if params[:reply_id].present?
      @message.parent = Message.find_by_id(params[:reply_id])
      @message.parent = nil unless @message.parent.visible_to?(current_user)
      @message.subject = @message.subject_from_parent
    end
  end

  def create
    @message = Message.new(params[:message].merge(sender: current_user))

    if params[:parent_id].present?
      @message.parent = Message.find_by_id(params[:parent_id])
      @message.parent = nil unless @message.parent.visible_to?(current_user)
      @message.recipient = @message.parent.sender
      @message.thread_id = @message.parent.thread_id || @message.parent.id
    end

    if @message.save
      flash[:success] = "Message sent!"
      redirect_to messages_path(view: 'inbox')
    else
      flash.now[:error] = @message.errors.full_messages.to_s
      use_javascript('messages')
      render :action => :new
    end
  end

  def show
    @message = Message.find_by_id(params[:id])
    @page_title = @message.subject
    unless @message
      flash[:error] = "Message could not be found."
      redirect_to messages_path(view: 'inbox') and return
    end

    unless @message.visible_to?(current_user)
      flash[:error] = "That is not your message!"
      redirect_to messages_path(view: 'inbox') and return
    end

    if @message.unread? and @message.recipient_id == current_user.id
      @message.update_attributes(unread: false)
    end
  end

  def update
  end

  def mark
    messages = Message.where(id: params[:marked_ids])
    box = 'inbox'
    messages.select! do |message|
      message.visible_to?(current_user)
    end
    flash[:success] = "Messages updated"
    if params[:commit] == "Mark Read / Unread"
      messages.each do |message|
        box = message.sender_id == current_user.id ? 'outbox' : 'inbox'
        message.update_attributes(unread: !message.unread?)
      end
    elsif params[:commit] == "Mark / Unmark Important"
      messages.each do |message|
        box = message.sender_id == current_user.id ? 'outbox' : 'inbox'
        box_attr = "marked_#{box}"
        message.update_attributes(box_attr => !message.send(box_attr+'?'))
      end
    elsif params[:commit] == "Delete"
      messages.each do |message|
        box = message.sender_id == current_user.id ? 'outbox' : 'inbox'
        box_attr = "visible_#{box}"
        message.update_attributes(box_attr => false, unread: false)
      end
    end
    redirect_to messages_path(view: box)
  end

  def destroy
  end
end
