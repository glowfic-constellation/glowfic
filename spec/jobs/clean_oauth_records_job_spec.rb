RSpec.describe CleanOauthRecordsJob do
  let(:application) { create(:oauth_application) }
  let(:user) { create(:user) }

  def token(**attrs)
    Doorkeeper::AccessToken.create!(application: application, resource_owner_id: user.id, expires_in: 2.hours.to_i, **attrs)
  end

  def grant(**attrs)
    Doorkeeper::AccessGrant.create!(application: application, resource_owner_id: user.id, expires_in: 10.minutes.to_i,
      redirect_uri: application.redirect_uri, **attrs,)
  end

  it 'deletes unusable tokens and grants and keeps the rest' do
    valid = token
    refreshable = token(use_refresh_token: true, created_at: 1.week.ago)
    revoked = token(revoked_at: 1.minute.ago)
    expired = token(created_at: 1.day.ago)
    current_grant = grant
    expired_grant = grant(created_at: 1.hour.ago)
    revoked_grant = grant(revoked_at: 1.minute.ago)
    nonce = Doorkeeper::OpenidConnect::Request.create!(access_grant: expired_grant, nonce: 'abc')

    CleanOauthRecordsJob.perform_now

    aggregate_failures do
      expect(Doorkeeper::AccessToken.pluck(:id)).to contain_exactly(valid.id, refreshable.id)
      expect(Doorkeeper::AccessGrant.pluck(:id)).to contain_exactly(current_grant.id)
      expect(Doorkeeper::OpenidConnect::Request.exists?(nonce.id)).to be(false)
      expect([revoked, expired, revoked_grant].map { |record| record.class.exists?(record.id) }).to all(be(false))
    end
  end

  it 'is enqueued at most once a day' do
    expect { 2.times { CleanOauthRecordsJob.enqueue_daily } }.to have_enqueued_job(CleanOauthRecordsJob).exactly(:once)
  end
end
