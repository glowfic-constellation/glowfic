require "spec_helper"

RSpec.describe ApplicationController do
  describe "#set_timezone" do
    it "uses the user's time zone within the block" do
      current_zone = Time.zone.name
      different_zone = ActiveSupport::TimeZone.all().detect { |z| z.name != Time.zone.name }.name
      session[:user_id] = create(:user, timezone: different_zone).id

      expect(Time.zone.name).to eq(current_zone)
      controller.send(:set_timezone) do
        expect(Time.zone.name).to eq(different_zone)
      end
    end

    it "succeeds when logged out" do
      current_zone = Time.zone.name
      expect(Time.zone.name).to eq(current_zone)
      controller.send(:set_timezone) do
        expect(Time.zone.name).to eq(current_zone)
      end
    end

    it "succeeds when logged in user has no zone set" do
      current_zone = Time.zone.name
      session[:user_id] = create(:user, timezone: nil).id
      expect(Time.zone.name).to eq(current_zone)
      controller.send(:set_timezone) do
        expect(Time.zone.name).to eq(current_zone)
      end
    end
  end
end
