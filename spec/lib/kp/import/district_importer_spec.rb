require "spec_helper"
require "kp/import/district_importer"

describe KP::Import::DistrictImporter do
  let(:csv) { "" }
  let(:school_type) { create(:school_type) }

  subject(:importer) { KP::Import::DistrictImporter.new(CSV.new(csv), school_type.id) }

  describe "parsing" do
    let(:csv) { "  district_id  ,  district_name   "}
    it "trims all values" do
      expect(importer.data[0][:attributes]).to eq(name: "district_name", extens_id: "district_id")
    end

    let(:error_csv) { "foo,bar,baz\napa,bepa\ncepa"}
    it "throws a parse error if there are rows with the wrong length" do
      expect {
        KP::Import::DistrictImporter.new(CSV.new(error_csv), school_type.id)
      }.to raise_error(
        KP::Import::ParseError,
        "1: Wrong row length (3 fields, expected 2) - foo\tbar\tbaz\n3: Wrong row length (1 fields, expected 2) - cepa"
      )
    end
  end

  describe ".valid?" do
    let(:csv) { "," } # Empty name
    it "does not accept invalid rows" do
      expect(importer.valid?).to be_false
    end
  end

  describe ".import!" do
    let(:csv) { "district_id,district_name" }
    let(:district) { District.first }

    before(:each) do
      expect(District.exists?).to be_false
    end

    it "creates new districts when an update cannot be found" do
      expect(importer.import!).not_to be_false
      expect(District.count).to eq 1
      expect(district.name).to eq "district_name"
      expect(district.extens_id).to eq "district_id"
      expect(district.school_type).to eq school_type
    end
    it "updates the name if there is an id match" do
      district = create(:district, name: "foo", extens_id: "district_id", school_type_id: school_type.id)
      expect(importer.import!).not_to be_false
      expect(District.count).to eq 1

      district.reload
      expect(district.name).to eq "district_name"
    end
    it "updates the id if there is a name match" do
      district = create(:district, name: "district_name", extens_id: "zomg", school_type_id: school_type.id)
      expect(importer.import!).not_to be_false
      expect(District.count).to eq 1

      district.reload
      expect(district.extens_id).to eq "district_id"
    end
    it "does not update districts from other school types" do
      district1 = create(:district, name: "district_name", extens_id: "zomg")
      district2 = create(:district, name: "foo", extens_id: "district_id")

      expect(importer.import!).not_to be_false
      expect(District.count).to eq 3

      expect(district1.reload.extens_id).to eq "zomg"
      expect(district2.reload.name).to eq "foo"
    end

    context "with duplicates" do
      let(:csv) { "district_id,district_name\ndistrict_id,district_name" }
      it "does not create duplicate districts" do
        expect(importer.import!).not_to be_false
        expect(District.where(extens_id: "district_id").count).to eq 1
      end
    end
  end
end

