class Api::V1::RepliesController < Api::ApiController
  resource_description do
    description 'Viewing replies to a post'
  end

  api! 'Load all the replies for a given post as JSON resources'
  param :post_id, :number, required: true, desc: "Post ID"
  param :page, :number, required: false, desc: 'Page in results'
  param :per_page, :number, required: false, desc: 'Number of replies to load per page. Defaults to 25, accepts values from 1-100 inclusive.'
  error 403, "Post is not visible to the user"
  error 404, "Post not found"
  example "'errors': [{'message': 'Post could not be found.'}]"
  example "'errors': [{'message': 'You do not have permission to perform this action.'}]"
  example "[
  {
    'id': 1,
    'content': 'dolor sit amet',
    'created_at': '2000-01-07T01:05:03Z',
    'updated_at': '2000-01-07T01:05:03Z',
    'character': null,
    'icon': null,
    'user': {
      'id': 2,
      'username': 'Marri2'
    }
  }, {
    'id': 2,
    'content': 'consectetur adipiscing elit',
    'created_at': '2000-01-08T01:02:03Z',
    'updated_at': '2000-01-08T01:02:03Z',
    'character': null,
    'icon': {
      'id': 7,
      'url': 'http://www.example.com/image.png',
      'keyword': 'icon'
    },
    'user': {
      'id': 1,
      'username': 'Marri1'
    }
  }
]"
  def index
    unless post = Post.find_by_id(params[:post_id])
      error = {message: "Post could not be found."}
      render json: {errors: [error]}, status: :not_found and return
    end

    access_denied and return unless post.visible_to?(current_user)

    replies = post.replies
      .select('replies.*, characters.name, characters.screenname, icons.keyword, icons.url, users.username')
      .joins(:user)
      .joins("LEFT OUTER JOIN characters ON characters.id = replies.character_id")
      .joins("LEFT OUTER JOIN icons ON icons.id = replies.icon_id")
      .order('id asc')
    paginate json: replies, per_page: per_page
  end
end
