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

  describe "#show_password_warning" do
    it "shows no warning if logged out" do
      controller.send(:show_password_warning) do
        expect(flash.now[:pass]).not_to eq("Because Marri accidentally made passwords a bit too secure, you must log back in to continue using the site.")
      end
    end

    it "shows no warning for users with salt_uuid" do
      user = create(:user)
      login_as(user)
      expect(user.salt_uuid).not_to be_nil
      controller.send(:show_password_warning) do
        expect(flash.now[:pass]).not_to eq("Because Marri accidentally made passwords a bit too secure, you must log back in to continue using the site.")
        expect(controller.send(:logged_in?)).to be_true
      end
    end

    it "shows warning if salt_uuid not set" do
      user = create(:user)
      login_as(user)
      user.update_attribute(:salt_uuid, nil)
      controller.send(:show_password_warning) do
        expect(flash.now[:pass]).to eq("Because Marri accidentally made passwords a bit too secure, you must log back in to continue using the site.")
        expect(controller.send(:logged_in?)).not_to be_true
      end
    end
  end
end
