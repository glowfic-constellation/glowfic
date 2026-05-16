RSpec.describe FlatPost do
  include ActiveJob::TestHelper

  describe "validations" do
    it "is limited to one per post" do
      post = create(:post)
      expect(post.flat_post).to be_present
      flatpost = FlatPost.create(post: post)
      expect(flatpost.persisted?).to be(false)
      expect(flatpost).not_to be_valid
      expect(flatpost.errors.messages).to eq({ post: ['has already been taken'] })
    end

    it "can have multiple on different posts" do
      create(:post)
      expect(FlatPost.count).to eq(1)
      post = create(:post)
      expect(post.flat_post).to be_valid
    end
  end

  describe ".regenerate_all" do
    def delete_lock(post)
      lock_key = GenerateFlatPostJob.lock_key(post.id)
      $redis.del(lock_key)
    end

    it "regenerates all flat posts" do
      post = create(:post)
      delete_lock(post)
      FlatPost.regenerate_all
      expect(GenerateFlatPostJob).to have_been_enqueued.with(post.id).on_queue('high')
    end

    it "regenerates only old flat posts with argument" do
      post = create(:post)
      nonpost = Timecop.freeze(post.tagged_at + 2.hours) { create(:post) }
      delete_lock(post)
      delete_lock(nonpost)
      FlatPost.regenerate_all(post.tagged_at + 1.hour)
      expect(GenerateFlatPostJob).to have_been_enqueued.with(post.id).on_queue('high')
      expect(GenerateFlatPostJob).not_to have_been_enqueued.with(nonpost.id).on_queue('high')
    end

    it "regenerates only matching flat posts with arguments" do
      post = create(:post)
      nonpost = create(:post)

      reply = build(:reply, post: post)
      reply.skip_regenerate = true
      reply.save!

      delete_lock(post)
      delete_lock(nonpost)
      FlatPost.regenerate_all(nil, false)
      expect(GenerateFlatPostJob).to have_been_enqueued.with(post.id).on_queue('high')
      expect(GenerateFlatPostJob).not_to have_been_enqueued.with(nonpost.id).on_queue('high')
    end

    it "handles missing flat posts" do
      post = create(:post)
      post.flat_post.delete
      delete_lock(post)
      FlatPost.regenerate_all
      expect(GenerateFlatPostJob).to have_been_enqueued.with(post.id).on_queue('high')
    end
  end

  describe "#body" do
    let(:post) { create(:post) }
    let(:flat_post) { post.flat_post }

    it "prefers the content column when present" do
      flat_post.update_columns(content: '<p>inline</p>', s3_key: 'flat_posts/whatever.html') # rubocop:disable Rails/SkipsModelValidations
      expect(S3_BUCKET).not_to receive(:object)
      expect(flat_post.body).to eq('<p>inline</p>')
    end

    it "fetches from S3 when only the s3_key is set" do
      flat_post.update_columns(content: nil, s3_key: 'flat_posts/42.html') # rubocop:disable Rails/SkipsModelValidations
      s3_object = double('Aws::S3::Object')
      s3_response = double('Aws::S3::Types::GetObjectOutput', body: StringIO.new('<p>from s3</p>'))
      expect(S3_BUCKET).to receive(:object).with('flat_posts/42.html').and_return(s3_object)
      expect(s3_object).to receive(:get).and_return(s3_response)

      expect(flat_post.body).to eq('<p>from s3</p>')
    end

    it "returns nil when neither is set" do
      flat_post.update_columns(content: nil, s3_key: nil) # rubocop:disable Rails/SkipsModelValidations
      expect(flat_post.body).to be_nil
    end
  end

  describe "#stream_body_to" do
    let(:post) { create(:post) }
    let(:flat_post) { post.flat_post }
    let(:io) { StringIO.new }

    it "writes the content column straight to the IO when present" do
      flat_post.update_columns(content: '<p>inline</p>', s3_key: nil) # rubocop:disable Rails/SkipsModelValidations
      expect(S3_BUCKET).not_to receive(:object)
      flat_post.stream_body_to(io)
      expect(io.string).to eq('<p>inline</p>')
    end

    it "streams chunks from S3 when only s3_key is set" do
      flat_post.update_columns(content: nil, s3_key: 'flat_posts/42.html') # rubocop:disable Rails/SkipsModelValidations
      s3_object = double('Aws::S3::Object')
      expect(S3_BUCKET).to receive(:object).with('flat_posts/42.html').and_return(s3_object)
      expect(s3_object).to receive(:get) do |&block|
        block.call('<p>chunk one </p>')
        block.call('<p>chunk two</p>')
      end

      flat_post.stream_body_to(io)
      expect(io.string).to eq('<p>chunk one </p><p>chunk two</p>')
    end

    it "writes nothing when neither is set" do
      flat_post.update_columns(content: nil, s3_key: nil) # rubocop:disable Rails/SkipsModelValidations
      flat_post.stream_body_to(io)
      expect(io.string).to eq('')
    end
  end
end
