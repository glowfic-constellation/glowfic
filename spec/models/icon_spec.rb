RSpec.describe Icon do
  include ActiveJob::TestHelper

  describe "#validations" do
    it "requires url" do
      icon = build(:icon, url: nil)
      expect(icon).not_to be_valid
      icon = build(:icon, url: '')
      expect(icon).not_to be_valid
    end

    it "requires url-looking url" do
      icon = build(:icon, url: 'not-a-url')
      expect(icon).not_to be_valid
    end

    it "requires user" do
      icon = build(:icon, user: nil)
      expect(icon).not_to be_valid
    end

    it "requires keyword" do
      icon = build(:icon, keyword: nil)
      expect(icon).not_to be_valid
      icon = build(:icon, keyword: '')
      expect(icon).not_to be_valid
    end

    it "requires short credit" do
      long_credit = 'aa' * 255
      icon = build(:icon, credit: long_credit)
      expect(icon).not_to be_valid
    end

    it "works with short credit" do
      short_credit = 'b' * 200
      icon = build(:icon, credit: short_credit)
      expect(icon).to be_valid
    end

    describe "#uploaded_url_yours" do
      it "does not allow url/s3_key mismatch", :aggregate_failures do
        icon = build(:icon, user: create(:user))
        icon.url = "https://d1anwqy6ci9o1i.cloudfront.net/users%2F#{icon.user.id}%2Ficons%2Fnonsense-fakeimg2.png"
        icon.s3_key = "users/#{icon.user.id + 1}/icons/nonsense-fakeimg2.png"
        expect(icon).not_to be_valid
        expect(icon.save).to be false
      end
    end
  end

  describe "#after_destroy" do
    it "updates reply ids" do
      reply = create(:reply, with_icon: true)
      perform_enqueued_jobs(only: UpdateModelJob) do
        Audited.audit_class.as_user(reply.user) { reply.icon.destroy! }
      end
      reply.reload
      expect(reply.icon_id).to be_nil
    end

    it "updates avatar ids" do
      icon = create(:icon)
      icon.user.avatar = icon
      icon.user.save!
      Audited.audit_class.as_user(icon.user) { icon.destroy! }
      expect(icon.user.reload.avatar_id).to be_nil
    end
  end

  describe "#use_https" do
    it "does not update sites that might not support HTTPS" do
      icon = build(:icon, url: 'http://www.example.com')
      icon.save!
      expect(icon.reload.url).to start_with('http:')
    end

    it "does update HTTP Dreamwidth icons on update" do
      icon = create(:icon, url: 'http://www.example.com')
      expect(icon.reload.url).to start_with('http:')
      icon.url = 'http://www.dreamwidth.org'
      icon.save!
      expect(icon.reload.url).to start_with('https:')
    end

    it "does update HTTP Imgur icons on create" do
      icon = build(:icon, url: 'http://i.imgur.com')
      icon.save!
      expect(icon.reload.url).to start_with('https:')
    end
  end

  describe "#delete_from_s3" do
    before(:each) { clear_enqueued_jobs }

    it "deletes uploaded on destroy" do
      icon = create(:uploaded_icon)
      Audited.audit_class.as_user(icon.user) { icon.destroy! }
      expect(DeleteIconFromS3Job).to have_been_enqueued.with(icon.s3_key).on_queue('high')
    end

    it "does not delete non-uploaded on destroy" do
      icon = create(:icon)
      Audited.audit_class.as_user(icon.user) { icon.destroy! }
      expect(DeleteIconFromS3Job).not_to have_been_enqueued
    end

    it "deletes uploaded on new uploaded update" do
      icon = create(:uploaded_icon)
      old_key = icon.s3_key
      icon.url = "https://d1anwqy6ci9o1i.cloudfront.net/users%2F#{icon.user.id}%2Ficons%2Fnonsense-fakeimg2.png"
      icon.s3_key = "users/#{icon.user.id}/icons/nonsense-fakeimg2.png"
      icon.save!
      expect(DeleteIconFromS3Job).to have_been_enqueued.with(old_key).on_queue('high')
    end

    it "does not delete uploaded on non-url update" do
      icon = create(:uploaded_icon)
      icon.keyword = "not a url update"
      icon.save!
      expect(DeleteIconFromS3Job).not_to have_been_enqueued
    end
  end

  describe "#use_icon_host" do
    let(:asset_host) { "https://fake.cloudfront.net" }

    before(:each) { allow(ENV).to receive(:fetch).and_call_original }

    it "does nothing unless asset host is present" do
      allow(ENV).to receive(:fetch).with('ICON_HOST', any_args).and_return(nil)
      icon = build(:icon, user: create(:user))
      url = "https://glowfic-bucket.s3.amazonaws.com/users%2F#{icon.user.id}%2Ficons%2Ffake_test.png"
      icon.s3_key = "users/#{icon.user_id}/icons/fake_test.png"
      icon.url = url
      icon.save!
      expect(icon.reload.url).to eq(url)
    end

    it "does nothing unless the icon is uploaded" do
      allow(ENV).to receive(:fetch).with('ICON_HOST', any_args).and_return(asset_host)
      icon = build(:icon, user: create(:user))
      url = "https://glowfic-bucket.s3.amazonaws.com/users%2F#{icon.user.id}%2Ficons%2Ffake_test.png"
      icon.s3_key = nil
      icon.url = url
      icon.save!
      expect(icon.reload.url).to eq(url)
    end

    it "does nothing unless the icon already has the asset host domain in it" do
      allow(ENV).to receive(:fetch).with('ICON_HOST', any_args).and_return(asset_host)
      icon = build(:icon, user: create(:user))
      url = "#{asset_host}/users%2F#{icon.user_id}%2Ficons%2Ffake_test.png"
      icon.s3_key = "users/#{icon.user_id}/icons/fake_test.png"
      icon.url = url
      icon.save!
      expect(icon.reload.url).to eq(url)
    end

    it "handles weird URL-less AWS edge case" do
      allow(ENV).to receive(:fetch).with('ICON_HOST', any_args).and_return(asset_host)
      icon = build(:uploaded_icon, url: '')
      expect(icon.save).to eq(false)
    end

    it "updates the s3 domain to the asset host domain" do
      allow(ENV).to receive(:fetch).with('ICON_HOST', any_args).and_return(asset_host)
      icon = build(:icon, user: create(:user))
      icon.url = "https://glowfic-bucket.s3.amazonaws.com/users%2F#{icon.user_id}%2Ficons%2Ffake_test.png"
      icon.s3_key = "users/#{icon.user_id}/icons/fake_test.png"
      icon.save!
      expect(icon.reload.url).to eq("#{asset_host}/users%2F#{icon.user_id}%2Ficons%2Ffake_test.png")
    end
  end

  describe "#update_flat_posts" do
    def update_uploaded_icon(icon)
      icon.update!(
        url: "https://d1anwqy6ci9o1i.cloudfront.net/users%2F#{user.id}%2Ficons%2Fnonsense-fakeimg-800.png",
        s3_key: "users/#{user.id}/icons/nonsense-fakeimg-800.png",
      )
    end

    def update_external_icon(icon)
      icon.update!(url: "https://www.fakeicon.com/new_icon", s3_key: nil)
    end

    shared_examples "works", :aggregate_failures do
      let(:post1) { create(:post, icon: icon, user: user) }
      let(:post2) { create(:post, unjoined_authors: [user]) }
      let(:reply) { create(:reply, icon: icon, post: post2, user: user) }

      before(:each) do
        perform_enqueued_jobs do
          post1
          reply
        end
      end

      it "updates posts on update to external icon" do
        update_external_icon(icon)
        expect(GenerateFlatPostJob).to have_been_enqueued.with(post1.id).on_queue('high')
        expect(GenerateFlatPostJob).to have_been_enqueued.with(post2.id).on_queue('high')
      end

      it "updates posts on update to uploaded icon" do
        update_uploaded_icon(icon)
        expect(GenerateFlatPostJob).to have_been_enqueued.with(post1.id).on_queue('high')
        expect(GenerateFlatPostJob).to have_been_enqueued.with(post2.id).on_queue('high')
      end

      it "updates posts on keyword edit" do
        icon.update!(keyword: 'new')
        expect(GenerateFlatPostJob).to have_been_enqueued.with(post1.id).on_queue('high')
        expect(GenerateFlatPostJob).to have_been_enqueued.with(post2.id).on_queue('high')
      end

      it "does not update posts on credit edit" do
        icon.update!(credit: 'new')
        expect(GenerateFlatPostJob).not_to have_been_enqueued.with(post1.id)
        expect(GenerateFlatPostJob).not_to have_been_enqueued.with(post2.id)
      end
    end

    context "with uploaded icons" do
      let(:user) { create(:user) }
      let(:icon) { create(:uploaded_icon, user: user) }

      it_behaves_like "works"
    end

    context "with external icons" do
      let(:user) { create(:user) }
      let(:icon) { create(:icon, user: user) }

      it_behaves_like "works"
    end
  end
end
