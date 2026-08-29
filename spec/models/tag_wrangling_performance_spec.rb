# Guards against the query patterns that make these features expensive: reveal
# resolution per tagging, scope resolution per tag, and unbounded growth in the
# wrangling queue. These assert query counts rather than wall time so they fail
# deterministically in CI.
RSpec.describe "tag wrangling performance" do # rubocop:disable RSpec/DescribeClass
  let(:author) { create(:user) }
  let(:reader) { create(:user) }

  describe "spoiler tag display" do
    it "loads a post's taggings in a constant number of queries" do
      post = create(:post, user: author)
      10.times { PostTag.create!(post: post, tag: create(:label), spoiler: true) }

      loaded = Post.find(post.id)
      reader.id # instantiate the let before measuring
      queries = count_queries { loaded.displayable_post_tags.each { |pt| pt.expanded_for?(reader) } }

      # post_tags plus tags, and nothing per tagging.
      expect(queries.size).to be <= 3
    end

    it "does not grow with the number of taggings" do
      post = create(:post, user: author)
      reader.id # instantiate the let before measuring
      3.times { PostTag.create!(post: post, tag: create(:label), spoiler: true) }
      small = count_queries { Post.find(post.id).displayable_post_tags.map { |pt| pt.expanded_for?(reader) } }.size

      20.times { PostTag.create!(post: post, tag: create(:label), spoiler: true) }
      large = count_queries { Post.find(post.id).displayable_post_tags.map { |pt| pt.expanded_for?(reader) } }.size

      expect(large).to eq(small)
    end

    it "reads no post view state when resolving display" do
      post = create(:post, user: author)
      create_list(:reply, 3, post: post, user: author)
      PostTag.create!(post: post, tag: create(:label), spoiler: true)

      loaded = Post.find(post.id)
      reader.id # instantiate the let before measuring
      loaded.displayable_post_tags.to_a
      queries = count_queries { loaded.displayable_post_tags.each { |pt| pt.expanded_for?(reader) } }

      expect(queries.join).not_to match(/post_views/i)
    end
  end

  describe "wrangler scope resolution" do
    it "walks the setting hierarchy in a bounded number of queries" do
      wrangler = create(:wrangler_user)
      root = create(:setting)
      WranglingAssignment.create!(user: wrangler, setting: root)

      parent = root
      10.times do
        child = create(:setting)
        Tag::MetaTag.create!(parent_tag: parent, child_tag: child)
        parent = child
      end

      queries = count_queries { WranglingAssignment.scope_ids_for(wrangler) }

      # One for the assignments, one to load the settings, one recursive CTE.
      expect(queries.size).to be <= 4
    end

    it "uses a single recursive query regardless of depth" do
      root = create(:setting)
      parent = root
      3.times do
        child = create(:setting)
        Tag::MetaTag.create!(parent_tag: parent, child_tag: child)
        parent = child
      end
      shallow = count_queries { root.descendant_ids }.size

      15.times do
        child = create(:setting)
        Tag::MetaTag.create!(parent_tag: parent, child_tag: child)
        parent = child
      end
      deep = count_queries { root.descendant_ids }.size

      expect(deep).to eq(shallow)
      expect(deep).to eq(1)
    end
  end

  describe "wrangling queue" do
    it "computes coverage without scanning per tag" do
      create_list(:label, 15).each { |tag| create(:post, labels: [tag]) }

      queries = count_queries { TagWrangling::Coverage.new.tap(&:percentage).remaining_tags }

      expect(queries.size).to be <= 5
    end

    it "clusters duplicates without a query per tag" do
      %w[Bar Fight Bars Fights barfight].each_with_index do |name, index|
        create(:label, name: "#{name}#{index}")
      end
      create(:label, name: 'Bar Fight')
      create(:label, name: 'bar fights')

      queries = count_queries { TagWrangling::DuplicateClusters.new.clusters }

      expect(queries.size).to be <= 3
    end
  end

  describe "reverse tag lookup" do
    it "filters spoilered taggings in the query rather than in Ruby" do
      tag = create(:label)
      create_list(:post, 3, labels: [tag])
      spoilered = create(:post)
      PostTag.create!(post: spoilered, tag: tag, spoiler: true)

      queries = count_queries { PostTag.for_reverse_lookup.where(tag_id: tag.id).pluck(:post_id) }

      expect(queries.size).to eq(1)
      expect(queries.first).to match(/spoiler/i)
    end
  end
end
