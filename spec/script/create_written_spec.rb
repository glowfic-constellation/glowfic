require Rails.root.join('script', 'create_written.rb').to_s

RSpec.describe "#create_writtens" do # rubocop:disable Rspec/DescribeClass
  let(:post) { create(:post) }

  it "skips posts that already have writtens" do
    create(:reply, post: post, reply_order: 0, content: post.content)
    expect { create_writtens }.not_to change{Reply.count}
  end

  it "creates writtens for simple posts" do
    post = create(:post, skip_written: true)
    expect(post.written).to be_nil
    Timecop.freeze(Time.zone.now + 8.hours) do
      expect { create_writtens }.to change{Reply.count}.by(1)
    end
    written = Reply.last
    expect(written.reply_order).to eq(0)
    expect(written.user).to eq(post.user)
    expect(written.content).to eq(post.content)
    expect(written.icon_id).to be_nil
    expect(written.character_id).to be_nil
    expect(written.character_alias_id).to be_nil
    expect(written.created_at).to be_the_same_time_as(post.created_at)
    expect(written.updated_at).to be_the_same_time_as(post.edited_at)
  end
end
