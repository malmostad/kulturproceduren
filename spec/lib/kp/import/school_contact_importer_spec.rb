require "spec_helper"
require "kp/import/school_contact_importer"

describe KP::Import::SchoolContactImporter do
  let(:csv) { "" }
  let(:school_type) { create(:school_type) }
  let(:district) { create(:district, school_type: school_type) }

  subject(:importer) { KP::Import::SchoolContactImporter.new(CSV.new(csv), school_type.id) }

  describe "parsing" do
    let(:csv) { "  school_id  ,  ignore, contact  "}
    it "trims all values" do
      expect(importer.data[0][:attributes]).to eq(school_id: "school_id", contact: "contact")
    end

    let(:error_csv) { "foo,bar\napa,bepa,cepa\ncepa"}
    it "throws a parse error if there are rows with the wrong length" do
      expect {
        KP::Import::SchoolContactImporter.new(CSV.new(error_csv), school_type.id)
      }.to raise_error(
        KP::Import::ParseError,
        "1: Wrong row length (2 fields, expected 3) - foo\tbar\n3: Wrong row length (1 fields, expected 3) - cepa"
      )
    end
  end

  describe ".import!" do
    let(:csv) { "school_id,ignore,contact" }
    let(:existing_contacts) { nil }
    let!(:school) { create(:school, district: district, extens_id: "school_id", contacts: existing_contacts) }

    it "adds the contact to the school's contacts" do
      expect(importer.import!).not_to be_false
      expect(school.reload.contacts).to eq "contact"
    end

    context "with duplicates in the import file" do
      let(:csv) { "school_id,ignore,contact\nschool_id,ignore,contact" }
      it "only adds one entry per contact" do
        expect(importer.import!).not_to be_false
        expect(school.reload.contacts).to eq "contact"
      end
    end

    context "with a blank contact" do
      let(:csv) { "school_id,ignore," }
      it "ignores blank contacts" do
        expect(importer.import!).not_to be_false
        expect(school.reload.contacts).to be_nil
      end
    end

    context "with existing contacts" do
      let(:csv) { "school_id,ignore,foo\nschool_id,ignore,contact\nschool_id,ignore,contact" }
      let(:existing_contacts) { "foo,bar" }
      it "adds any new contacts to the school" do
        expect(importer.import!).not_to be_false
        expect(school.reload.contacts.split(",")).to match_array(%w(foo bar contact))
      end

      context "and a blank contact" do
        let(:csv) { "school_id,ignore," }
        it "ignores blank contacts" do
          expect(importer.import!).not_to be_false
          expect(school.reload.contacts.split(",")).to match_array(%w(foo bar))
        end
      end

      it "sorts the contacts to avoid unneccessary updates" do
        expect(importer.import!).not_to be_false
        expect(school.reload.contacts).to eq("bar,contact,foo")
      end
    end

    context "with another school type" do
      let(:csv) { "other_school_id,ignore,contact" }
      let!(:school) { create(:school, extens_id: "other_school_id", contacts: nil) }

      it "does not add the contacts" do
        expect(importer.import!).not_to be_false
        expect(school.reload.contacts).to be_nil
      end
    end
  end
end

