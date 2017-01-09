# frozen_string_literal: true
class MessagesController < ApplicationController
  before_filter :login_required

  def index
    if params[:view] == 'outbox'
      @view = 'outbox'
      @page_title = 'Outbox'
      @messages = current_user.sent_messages.where(visible_outbox: true).order('id desc')
    else
      @view = 'inbox'
      @page_title = 'Inbox'
      @messages = current_user.messages.where(visible_inbox: true).order('id desc')
    end
  end

  def new
    use_javascript('messages')
    @message = Message.new
    @message.recipient = User.find_by_id(params[:recipient_id])
    @page_title = 'Compose Message'
    if params[:reply_id].present?
      @message.parent = Message.find_by_id(params[:reply_id])
      unless @message.parent.present?
        @message.parent = nil
        flash.now[:error] = "Message parent could not be found."
        return
      end

      unless @message.parent.visible_to?(current_user)
        @message.parent = nil
        flash.now[:error] = "You do not have permission to reply to that message."
        return
      end

      @message.subject = @message.subject_from_parent
      @message.thread_id = @message.parent.thread_id || @message.parent.id
      @message.recipient_id = @message.parent.sender_id # set recipient to parent's sender

      if @message.recipient_id == current_user.id # if recipient is self
        @message.recipient_id = @message.parent.recipient_id # use the same recipient as the parent message
      end
    end
  end

  def create
    @message = Message.new(params[:message].merge(sender: current_user))

    if params[:parent_id].present?
      @message.parent = Message.find_by_id(params[:parent_id])

      unless @message.parent && @message.parent.visible_to?(current_user)
        @message.parent = nil
        flash.now[:error] = "Parent could not be found."
        use_javascript('messages')
        @page_title = 'Compose Message'
        render :action => :new
        return
      end

      @message.thread_id = @message.parent.thread_id
      @message.recipient_id ||= @message.parent.sender_id
    end

    if @message.parent
      if @message.recipient_id != @message.parent.sender_id && @message.recipient_id != @message.parent.recipient_id
        # this message is attemptedly not actually part of the conversation
        # so someone sent invalid data to the form, or something weird happened
        @message.recipient_id = nil
        flash.now[:error] = "Forwarding is not yet implemented."
        use_javascript('messages')
        @page_title = 'Compose Message'
        render :action => :new
        return
      else
        # set the recipient to whoever's not sending it of the conversation partners
        @message.recipient_id = if @message.sender_id == @message.parent.sender_id
          @message.parent.recipient_id
        else
          @message.parent.sender_id
        end
      end
    end

    if params[:button_preview]
      render :action => 'preview' and return
    end

    if @message.save
      flash[:success] = "Message sent!"
      redirect_to messages_path(view: 'inbox')
    else
      flash.now[:error] = {}
      flash.now[:error][:array] = @message.errors.full_messages
      flash.now[:error][:message] = "Your message could not be sent because of the following problems:"
      use_javascript('messages')
      @page_title = 'Compose Message'
      render :action => :new
    end
  end

  def show
    @message = Message.find_by_id(params[:id])
    unless @message
      flash[:error] = "Message could not be found."
      redirect_to messages_path(view: 'inbox') and return
    end

    unless @message.visible_to?(current_user)
      flash[:error] = "That is not your message!"
      redirect_to messages_path(view: 'inbox') and return
    end

    @page_title = @message.unempty_subject
    if @message.unread? and @message.recipient_id == current_user.id
      @message.update_attributes(unread: false)
    end
  end

  def mark
    box = nil
    messages = Message.where(id: params[:marked_ids]).select do |message|
      message.visible_to?(current_user)
    end

    if params[:commit] == "Mark Read / Unread"
      messages.each do |message|
        box ||= message.box(current_user)
        message.update_attributes(unread: !message.unread?)
      end
    elsif params[:commit] == "Mark / Unmark Important"
      messages.each do |message|
        box ||= message.box(current_user)
        box_attr = "marked_#{box}"
        message.update_attributes(box_attr => !message.send(box_attr+'?'))
      end
    elsif params[:commit] == "Delete"
      messages.each do |message|
        box ||= message.box(current_user)
        box_attr = "visible_#{box}"
        message.update_attributes(box_attr => false, unread: false)
      end
    else
      flash[:error] = "Could not perform unknown action."
      redirect_to messages_path and return
    end

    flash[:success] = "Messages updated"
    redirect_to messages_path(view: box || 'inbox')
  end
end
