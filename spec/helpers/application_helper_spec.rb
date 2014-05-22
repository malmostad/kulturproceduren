require "spec_helper"

describe ApplicationHelper do
  describe "#malmo_body_class" do
    before(:each) do
      @env = Rails.env
    end
    after(:each) do
      Rails.env = @env
    end
    it "is nothing when the Rails environment is production" do
      Rails.env = "production"
      expect(helper.malmo_body_class()).to be_blank
    end
    it "returns 'development' when the Rails environment is development" do
      Rails.env = "development"
      expect(helper.malmo_body_class()).to eq "development"
    end
    it "returns 'test' when the Rails environment is acceptance" do
      Rails.env = "acceptance"
      expect(helper.malmo_body_class()).to eq "test"
    end
    it "returns 'staging' when the Rails environment anything other than production, acceptance or development" do
      Rails.env = "zomglol"
      expect(helper.malmo_body_class()).to eq "staging"
    end
  end
end
