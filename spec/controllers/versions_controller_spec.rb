require 'spec_helper'

describe VersionsController, versioning: true do
  before(:each) do
    controller.should_receive(:authenticate).at_least(:once).and_return(true)
    controller.should_receive(:require_admin).at_least(:once).and_return(true)
  end

  describe "PUT #revert" do
    context "basic revert" do
      let(:district) { create(:district, name: "District") }
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

      it "saves a version before reverting" do
        expect(district.versions.count).to eq(2)
        put :revert, id: version.id
        expect(district.versions.count).to eq(3)
      end
    end
    context "with extra data" do
      let(:group) { create(:group_with_age_groups, _age_group_data: [[10, 2], [11, 3]]) }
      let(:version) { group.versions.last }

      before(:each) do
        group.touch_with_version
        group.set_extra_data_from_version!(10 => 3, 12 => 4)
      end

      it "calls .set_extra_data_from_version! with the extra data" do
        put :revert, id: version.id
        expect(response).to redirect_to(group)
        expect(group.age_group_data).to eq(10 => 2, 11 => 3)
      end

      it "saves a version before reverting" do
        expect(group.versions.count).to eq(2)
        put :revert, id: version.id
        expect(group.versions.count).to eq(3)
      end
    end
  end
end
