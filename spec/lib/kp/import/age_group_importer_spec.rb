require "spec_helper"
require "kp/import/age_group_importer"

describe KP::Import::AgeGroupImporter do
  let(:csv) { "" }
  let(:school_type) { create(:school_type) }
  let(:district) { create(:district, school_type: school_type) }
  let(:school) { create(:school, district: district) }

  subject(:importer) { KP::Import::AgeGroupImporter.new(CSV.new(csv), school_type.id) }

  describe "parsing" do
    let(:csv) { "  ignore  ,  group_id  , ignore ,   ignore , 1   ,2004 "}
    it "trims the strings" do
      expect(importer.data[0][:attributes]).to include(group_id: "group_id")
    end
    it "converts the numbers to integers" do
      expect(importer.data[0][:attributes]).to include(quantity: 1, birth_year: 2004)
    end

    let(:error_csv) { "foo,bar,baz\napa,bepa,cepa,depa,epa,fepa\ngepa"}
    it "throws a parse error if there are rows with the wrong length" do
      expect {
        KP::Import::AgeGroupImporter.new(CSV.new(error_csv), school_type.id)
      }.to raise_error(
        KP::Import::ParseError,
        "1: Wrong row length (3 fields, expected 6) - foo\tbar\tbaz\n3: Wrong row length (1 fields, expected 6) - gepa")
    end
  end

  describe ".valid?" do
    let(:csv) { "ignore,group_id,ignore,ignore,," } # Empty amount and birth year
    let!(:group) { create(:group, school: school, extens_id: "group_id") }
    it "does not accept invalid rows" do
      expect(importer.valid?).to be_false
    end
  end

  describe ".import!" do
    let(:csv) { "ignore,group_id,ignore,ignore,10,2000\nignore,group_id,ignore,ignore,5,2001" }
    let(:freeze_date) { Time.local(2014, 3, 1, 12, 0) }
    let!(:group) { create(:group, school: school, extens_id: "group_id") }

    before(:each) do
      Timecop.freeze(freeze_date)
    end

    after(:each) do
      Timecop.return
    end

    it "uses the last year as the base year for ages in the spring" do
      expect(importer.import!).not_to be_false
      expect(group.age_groups.where(age: 12).count).to eq 1
      expect(group.age_groups.where(age: 13).count).to eq 1
    end

    it "adds the age groups to the group" do
      expect(importer.import!).not_to be_false
      expect(group.age_groups(true)).to have(2).items

      age_group1 = group.age_groups.detect { |ag| ag.age == 13 }
      age_group2 = group.age_groups.detect { |ag| ag.age == 12 }

      expect(age_group1.quantity).to eq 10
      expect(age_group2.quantity).to eq 5
    end

    it "handles existing age groups" do
      create(:age_group, group: group, age: 11, quantity: 10)
      create(:age_group, group: group, age: 12, quantity: 11)

      expect(importer.import!).not_to be_false

      expect(group.age_groups(true)).to have(2).items

      age_group1 = group.age_groups.detect { |ag| ag.age == 13 }
      age_group2 = group.age_groups.detect { |ag| ag.age == 12 }

      expect(age_group1.quantity).to eq 10
      expect(age_group2.quantity).to eq 5
    end

    it "does not remove age groups groups that are not referenced in the import" do
      other_group = create(:group, school: school, extens_id: "other_group_id")
      age_groups = [
        create(:age_group, group: other_group),
        create(:age_group, group: other_group)
      ]

      expect(importer.import!).not_to be_false

      expect(other_group.age_groups(true)).to match_array(age_groups)
    end

    context "with unknown groups" do
      let(:csv) { "ignore,unknown_group_id,ignore,ignore,10,2000\nignore,unknown_group_id,ignore,ignore,5,2001" }
      it "ignores age groups for unknown groups" do
        expect(importer.import!).not_to be_false
        expect(AgeGroup.exists?).to be_false
      end
    end

    context "with different school type" do
      let(:csv) { "ignore,other_group_id,ignore,ignore,10,2000\nignore,other_group_id,ignore,ignore,5,2001" }
      let!(:other_group) { create(:group, extens_id: "other_group_id") }
      it "does not touch the age groups" do
        expect(importer.import!).not_to be_false
        expect(AgeGroup.exists?).to be_false
      end
    end

    context "in the autumn" do
      let(:freeze_date) { Time.local(2013, 10, 1, 12, 0) }
      it "uses the current year as the base year for ages" do
        expect(importer.import!).not_to be_false
        expect(group.age_groups.where(age: 12).count).to eq 1
        expect(group.age_groups.where(age: 13).count).to eq 1
      end
    end
  end
end

