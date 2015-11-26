class MessagesController < ApplicationController
  before_filter :login_required

  def index
    if params[:view] == 'outbox'
      @view = 'outbox'
      @messages = current_user.messages # TODO
    else
      @view = 'inbox'
      @messages = current_user.messages
    end
  end

  def new
  end

  def create
  end

  def show
  end

  def edit
  end

  def update
  end

  def icon
  end

  def destroy
  end
end
