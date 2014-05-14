require "spec_helper"
require "kp/import/group_contact_importer"

describe KP::Import::GroupContactImporter do
  let(:csv) { "" }
  let(:school_type) { create(:school_type) }
  let(:district) { create(:district, school_type: school_type) }
  let(:school) { create(:school, district: district) }

  subject(:importer) { KP::Import::GroupContactImporter.new(CSV.new(csv), school_type.id) }

  describe "parsing" do
    let(:csv) { "  group_id  ,  ignore,ignore , contact  "}
    it "trims all values" do
      expect(importer.data[0][:attributes]).to eq(group_id: "group_id", contact: "contact")
    end

    let(:error_csv) { "foo,bar,baz\napa,bepa,cepa,depa\ncepa"}
    it "throws a parse error if there are rows with the wrong length" do
      expect {
        KP::Import::GroupContactImporter.new(CSV.new(error_csv), school_type.id)
      }.to raise_error(
        KP::Import::ParseError,
        "1: Wrong row length (3 fields, expected 4) - foo\tbar\tbaz\n3: Wrong row length (1 fields, expected 4) - cepa"
      )
    end
  end

  describe ".import!" do
    let(:csv) { "group_id,ignore,ignore,contact" }
    let(:existing_contacts) { nil }
    let!(:group) { create(:group, school: school, extens_id: "group_id", contacts: existing_contacts) }

    it "adds the contact to the group's contacts" do
      expect(importer.import!).not_to be_false
      expect(group.reload.contacts).to eq "contact"
    end

    context "with duplicates in the import file" do
      let(:csv) { "group_id,ignore,ignore,contact\ngroup_id,ignore,ignore,contact" }
      it "only adds one entry per contact" do
        expect(importer.import!).not_to be_false
        expect(group.reload.contacts).to eq "contact"
      end
    end

    context "with a blank contact" do
      let(:csv) { "group_id,ignore,ignore," }
      it "ignores blank contacts" do
        expect(importer.import!).not_to be_false
        expect(group.reload.contacts).to be_nil
      end
    end

    context "with existing contacts" do
      let(:csv) { "group_id,ignore,ignore,foo\ngroup_id,ignore,ignore,contact\ngroup_id,ignore,ignore,contact" }
      let(:existing_contacts) { "foo,bar" }
      it "adds any new contacts to the group" do
        expect(importer.import!).not_to be_false
        expect(group.reload.contacts.split(",")).to match_array(%w(foo bar contact))
      end

      context "and a blank contact" do
        let(:csv) { "group_id,ignore,ignore," }
        it "ignores blank contacts" do
          expect(importer.import!).not_to be_false
          expect(group.reload.contacts.split(",")).to match_array(%w(foo bar))
        end
      end

      it "sorts the contacts to avoid unneccessary updates" do
        expect(importer.import!).not_to be_false
        expect(group.reload.contacts).to eq("bar,contact,foo")
      end
    end

    context "with another school type" do
      let(:csv) { "other_group_id,ignore,ignore,contact" }
      let!(:group) { create(:group, extens_id: "other_group_id", contacts: nil) }

      it "does not add the contacts" do
        expect(importer.import!).not_to be_false
        expect(group.reload.contacts).to be_nil
      end
    end
  end
end

