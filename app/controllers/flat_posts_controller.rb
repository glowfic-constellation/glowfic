# frozen_string_literal: true

# Serves the flat (single-page) view of a post via a streaming response so
# the rendered reply body never has to be fully materialized in a Ruby
# string — peak controller memory is O(chrome) + O(chunk_size from S3),
# independent of post length.
#
# This is a separate controller from PostsController specifically so that
# `ActionController::Live` doesn't apply to ALL post actions. Live changes
# every response on its including controller to use a threaded response,
# which Capybara's test driver can't reliably handle for non-streaming
# actions.
class FlatPostsController < ApplicationController
  include ActionController::Live

  # Marker rendered into the flat view template that the streaming path
  # splits the chrome on, replacing it with the actual reply body written
  # straight to the response stream.
  FLAT_BODY_PLACEHOLDER = "\u{2603}__GLOWFIC_FLAT_BODY__\u{2603}"

  before_action :find_post

  def show
    response.headers['X-Robots-Tag'] = 'noindex'
    response.headers['Content-Type'] = 'text/html; charset=utf-8'
    chrome = render_to_string(template: 'posts/flat', layout: false)
    prefix, suffix = chrome.split(FLAT_BODY_PLACEHOLDER, 2)
    response.stream.write(prefix)
    @post.flat_post&.stream_body_to(response.stream)
    response.stream.write(suffix) if suffix
  rescue ActionController::Live::ClientDisconnected, IOError
    # client went away mid-stream — nothing more to do
  ensure
    response.stream.close
  end

  private

  def find_post
    @post = Post.find_by(id: params[:id])
    if @post.nil?
      flash[:error] = "Post could not be found."
      redirect_to continuities_path
    elsif !@post.visible_to?(current_user)
      flash[:error] = "You do not have permission to view this post."
      redirect_to continuities_path
    end
  end
end
