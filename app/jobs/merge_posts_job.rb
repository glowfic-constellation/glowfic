# frozen_string_literal: true
class MergePostsJob < ApplicationJob
  queue_as :low

  def perform(_source_post_id, _target_reply_id, _privacy, _setting_ids, _content_warning_ids, _label_ids)
    # TODO(post-merger): perform the merge
  end
end
