# frozen_string_literal: true
class MessagesController < ApplicationController
  before_filter :login_required
  before_filter :editor_setup, only: :new

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
    @message = Message.new
    @message.recipient = User.find_by_id(params[:recipient_id])

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
      @message.thread_id = @message.parent.thread_id
      @message.recipient_id = @message.parent.user_ids.detect { |id| id != current_user.id }
    end
  end

  def create
    @message = Message.new((params[:message] || {}).merge(sender: current_user))

    if params[:parent_id].present?
      @message.parent = Message.find_by_id(params[:parent_id])

      unless @message.parent && @message.parent.visible_to?(current_user)
        @message.parent = nil
        flash.now[:error] = "Parent could not be found."
        editor_setup
        render :action => :new and return
      end

      @message.thread_id = @message.parent.thread_id
      @message.recipient_id = @message.parent.user_ids.detect { |id| id != current_user.id }
    end

    render :action => 'preview' and return if params[:button_preview]

    unless @message.save
      flash.now[:error] = {}
      flash.now[:error][:array] = @message.errors.full_messages
      flash.now[:error][:message] = "Your message could not be sent because of the following problems:"
      editor_setup
      render :action => :new and return
    end

    flash[:success] = "Message sent!"
    redirect_to messages_path(view: 'inbox')
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

  private

  def editor_setup
    use_javascript('messages')
    @page_title = 'Compose Message'
  end
end
