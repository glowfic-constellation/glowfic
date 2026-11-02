# frozen_string_literal: true
class Api::V1::MessagesController < Api::ApiController
  before_action :login_required
  before_action :readonly_forbidden

  resource_description do
    description "Viewing the current user's private messages"
  end

  api :GET, '/messages', "Load the current user's inbox or outbox, with one entry per thread, newest first"
  header 'Authorization', 'Authorization token for a user in the format "Authorization" : "Bearer [token]"', required: true
  param :box, ['inbox', 'outbox'], required: false, desc: "Which box to load. Defaults to 'inbox'."
  param :page, :number, required: false, desc: 'Page in results'
  param :per_page, :number, required: false, desc: 'Number of threads to load per page. Defaults to 25, accepts values from 1-100 inclusive.'
  error 401, "You must be logged in"
  error 403, "Read-only accounts cannot use messages"
  error 422, "Invalid parameters provided"
  def index
    box = (params[:box] == 'outbox') ? 'outbox' : 'inbox'
    queryset = Message.from(Message.box_threads_for(current_user, box), "messages").joins(:first_thread)
      .select('messages.*', 'first_threads_messages.subject AS thread_subject', 'first_threads_messages.created_at AS thread_created_at')
      .includes(:sender, :recipient).order('messages.id desc')
    messages = paginate queryset, per_page: per_page

    thread_ids = messages.map(&:thread_id)
    thread_counts = Message.where(thread_id: thread_ids).group(:thread_id).count
    unread_thread_ids = Message.where(thread_id: thread_ids, recipient_id: current_user.id).unread.distinct.pluck(:thread_id)

    results = messages.map do |message|
      message.as_json(viewer: current_user).merge(
        thread: {
          id: message.thread_id,
          subject: message.unempty_subject,
          created_at: message.thread_created_at,
          message_count: thread_counts[message.thread_id],
          unread: unread_thread_ids.include?(message.thread_id),
        },
      )
    end
    render json: { box: box, results: results }
  end

  api :GET, '/messages/:id', 'Load a message and all the messages in its thread. This does not mark any messages as read.'
  header 'Authorization', 'Authorization token for a user in the format "Authorization" : "Bearer [token]"', required: true
  param :id, :number, required: true, desc: "Message ID"
  error 401, "You must be logged in"
  error 403, "Message is not visible to the user, or the user has a read-only account"
  error 404, "Message not found"
  error 422, "Invalid parameters provided"
  def show
    return unless (message = find_object(Message))

    if message.sender&.deleted? || message.recipient.deleted?
      error = { message: "Message could not be found." }
      render json: { errors: [error] }, status: :not_found and return
    end

    access_denied and return unless message.visible_to?(current_user)

    thread = Message.where(thread_id: message.thread_id).includes(:sender, :recipient).ordered_by_id
    render json: {
      message: message.as_json(viewer: current_user),
      box: message.box(current_user),
      thread: {
        id: message.thread_id,
        subject: message.unempty_subject,
        messages: thread.map { |thread_message| thread_message.as_json(viewer: current_user) },
      },
    }
  end

  private

  def readonly_forbidden
    return unless current_user.read_only?
    error = { message: "This feature is not available to read-only accounts." }
    render json: { errors: [error] }, status: :forbidden
  end
end
