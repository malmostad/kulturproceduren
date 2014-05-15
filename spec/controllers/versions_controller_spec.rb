require 'spec_helper'

describe VersionsController, versioning: true do
  before(:each) do
    controller.should_receive(:authenticate).at_least(:once).and_return(true)
    controller.should_receive(:require_admin).at_least(:once).and_return(true)
  end

  describe "PUT #revert" do
    let!(:district) { create(:district, name: "District") }
    let(:version) { district.versions.last }

    before(:each) do
      district.name = "District updated" # Generate an update version
      district.save!
    end

    it "reverts the version's item to the given version and redirects to the item" do
      put :revert, id: version.id
      expect(response).to redirect_to(district)
      expect(district.reload.name).to eq("District")
    end
  end
end
