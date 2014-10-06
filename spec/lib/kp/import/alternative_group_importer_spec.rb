require "spec_helper"
require "kp/import/alternative_group_importer"

describe KP::Import::AlternativeGroupImporter do
  let(:csv) { "" }
  let(:school_type) { create(:school_type) }
  let(:district) { create(:district, school_type: school_type) }

  subject(:importer) { KP::Import::AlternativeGroupImporter.new(CSV.new(csv), school_type.id) }

  describe "parsing" do
    let(:csv) { "  school_id  ,  group_id  , group_name , ignore, ignore   , ignore"}
    it "trims all values" do
      expect(importer.data[0][:attributes]).to eq(name: "group_name", extens_id: "group_id", school_id: "school_id")
    end

    let(:error_csv) { "foo,bar,baz\napa,bepa,cepa,depa,epa,fepa\nepa"}
    it "throws a parse error if there are rows with the wrong length" do
      expect {
        KP::Import::AlternativeGroupImporter.new(CSV.new(error_csv), school_type.id)
      }.to raise_error(
        KP::Import::ParseError,
        "1: Wrong row length (3 fields, expected 6) - foo\tbar\tbaz\n3: Wrong row length (1 fields, expected 6) - epa"
      )
    end
  end

  describe ".valid?" do
    let(:csv) { "school_id,group_id,,ignore,ignore,ignore" } # Empty name
    let!(:school) { create(:school, district: district, extens_id: "school_id") }
    it "does not accept invalid rows" do
      expect(importer.valid?).to be_false
    end
  end

  describe ".import!" do
    let(:csv) { "school_id,group_id,group_name,ignore,ignore,ignore" }
    let!(:school) { create(:school, district: district, extens_id: "school_id") }
    let(:group) { Group.first }

    before(:each) do
      expect(Group.exists?).to be_false
    end

    it "creates new groups when an update cannot be found" do
      expect(importer.import!).not_to be_false
      expect(Group.count).to eq 1
      expect(group.name).to eq "group_name"
      expect(group.extens_id).to eq "group_id"
      expect(group.school).to eq school
      expect(group.active).to be_true
    end
    it "updates the name if there is an id match" do
      group = create(:group, name: "foo", extens_id: "group_id", school: school)
      expect(importer.import!).not_to be_false
      expect(Group.count).to eq 1

      group.reload
      expect(group.name).to eq "group_name"
    end
    it "activates inactive groups" do
      group = create(:group, extens_id: "group_id", school: school, active: false)
      expect(importer.import!).not_to be_false
      expect(Group.count).to eq 1

      group.reload
      expect(group.active).to be_true
    end

    context "with different school type" do
      let(:csv) { "other_school_id,other_group_id,group_name,ignore,ignore,ignore" }
      let(:other_school) { create(:school, extens_id: "other_school_id") }
      let!(:other_group) { create(:group, name: "foo", extens_id: "other_group_id", school: other_school) }

      it "does not update groups" do
        expect(importer.import!).not_to be_false
        expect(Group.count).to eq 1

        expect(other_group.reload.name).to eq "foo"
      end
    end

    context "with unknown school ids" do
      let(:csv) { "school_id,group_id,group_name,ignore,ignore,ignore\nunknown,group_id2,group_name2,ignore,ignore,ignore" }
      it "creates new schools when an update cannot be found" do
        expect(importer.import!).not_to be_false
        expect(Group.count).to eq 1
        expect(group.name).to eq "group_name"
      end
    end

    context "with duplicates" do
      let(:csv) { "school_id,group_id,group_name,ignore,ignore,ignore\nschool_id,group_id,group_name,ignore,ignore,ignore" }
      it "does not create duplicate districts" do
        expect(importer.import!).not_to be_false
        expect(Group.where(extens_id: "group_id").count).to eq 1
      end
    end
  end
end

