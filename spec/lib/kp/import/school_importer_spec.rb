require "spec_helper"
require "kp/import/school_importer"

describe KP::Import::SchoolImporter do
  let(:csv) { "" }
  let(:school_type) { create(:school_type) }

  subject(:importer) { KP::Import::SchoolImporter.new(CSV.new(csv), school_type.id) }

  describe "parsing" do
    let(:csv) { "  school_id  ,  district_id  , school_name "}
    it "trims all values" do
      expect(importer.data[0][:attributes]).to eq(name: "school_name", extens_id: "school_id", district_id: "district_id")
    end

    let(:error_csv) { "foo,bar,baz\napa,bepa\ncepa"}
    it "throws a parse error if there are rows with the wrong length" do
      expect {
        KP::Import::SchoolImporter.new(CSV.new(error_csv), school_type.id)
      }.to raise_error(
        KP::Import::ParseError,
        "2: Wrong row length (2 fields, expected 3) - apa\tbepa\n3: Wrong row length (1 fields, expected 3) - cepa"
      )
    end
  end

  describe ".valid?" do
    let(:csv) { "school_id,district_id," } # Empty name
    let!(:district) { create(:district, school_type: school_type, extens_id: "district_id") }
    it "does not accept invalid rows" do
      expect(importer.valid?).to be_false
    end
  end

  describe ".import!" do
    let(:csv) { "school_id,district_id,school_name" }
    let!(:district) { create(:district, school_type: school_type, extens_id: "district_id") }
    let(:school) { School.first }

    before(:each) do
      expect(School.exists?).to be_false
    end

    it "creates new schools when an update cannot be found" do
      expect(importer.import!).not_to be_false
      expect(School.count).to eq 1
      expect(school.name).to eq "school_name"
      expect(school.extens_id).to eq "school_id"
      expect(school.district).to eq district
    end
    it "updates the name if there is an id match" do
      school = create(:school, name: "foo", extens_id: "school_id", district: district)
      expect(importer.import!).not_to be_false
      expect(School.count).to eq 1

      school.reload
      expect(school.name).to eq "school_name"
    end
    it "updates the id if there is a name match" do
      school = create(:school, name: "school_name", extens_id: "zomg", district: district)
      expect(importer.import!).not_to be_false
      expect(School.count).to eq 1

      school.reload
      expect(school.extens_id).to eq "school_id"
    end

    context "with different school type" do
      let(:csv) { "school_id,other_district_id,school_name" }

      let(:other_district) { create(:district, extens_id: "other_district_id") }
      let!(:school1) { create(:school, district: other_district, name: "school_name", extens_id: "zomg") }
      let!(:school2) { create(:school, district: other_district, name: "foo", extens_id: "school_id") }

      it "does not update schools from other school types" do
        expect(importer.import!).not_to be_false
        expect(School.count).to eq 2

        expect(school1.reload.extens_id).to eq "zomg"
        expect(school2.reload.name).to eq "foo"
      end
    end

    context "with unknown district ids" do
      let(:csv) { "school_id,district_id,school_name\nschool_id2,unknown,school_name2" }
      it "creates new schools when an update cannot be found" do
        expect(importer.import!).not_to be_false
        expect(School.count).to eq 1
        expect(school.name).to eq "school_name"
      end
    end

    context "with duplicates" do
      let(:csv) { "school_id,district_id,school_name\nschool_id,district_id,school_name" }
      it "does not create duplicate districts" do
        expect(importer.import!).not_to be_false
        expect(School.where(extens_id: "school_id").count).to eq 1
      end
    end
  end
end

