# frozen_string_literal: true
# Filters a post relation down to the posts that the current user should see in a post list:
# posts visible to them, minus posts hidden by their blocks and (by default) Site testing posts.
# Shared between the HTML controllers and the API so both apply the same rules.
module PostListFilter
  extend ActiveSupport::Concern

  included do
    protected

    def posts_relation_filter(posts, no_tests: true, show_blocked: false)
      posts = posts.where.not(id: current_user.hidden_posts) if logged_in? && !show_blocked
      posts = posts.no_tests if no_tests
      posts.visible_to(current_user)
    end
  end
end
