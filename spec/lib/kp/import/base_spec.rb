require "spec_helper"
require "kp/import/base"

class KP::Import::Dummy < KP::Import::Base
  def initialize(csv, csv_header = false)
    super(csv, csv_header)
  end
  def attributes_from_row(row)
    return { first: row[0], second: row[1] } if row.length == 2
  end
  def unique_id(attributes)
  end
  def build(attributes)
  end
end
class KP::Import::DummyRaiser < KP::Import::Base
  def initialize(csv, csv_header = false)
    super(csv, csv_header)
  end
  def unique_id(attributes)
  end
  def attributes_from_row(row)
    raise KP::Import::ParseError.new(row[0])
  end
  def build(attributes)
  end
end

describe KP::Import::Base do
  let(:csv_header) { false }
  let(:csv) { "" }

  subject(:importer) { KP::Import::Dummy.new(CSV.new(csv), csv_header) }

  describe "constructor" do
    let(:csv) { "foo,bar\nbaz,apa" }
    it "calls .attributes_from_row for each row, and stores it in .data" do
      expect(importer.data).to have(2).items
      expect(importer.data[0][:original_row]).to eq(%w(foo bar))
      expect(importer.data[0][:attributes]).to eq(first: "foo", second: "bar")
      expect(importer.data[1][:original_row]).to eq(%w(baz apa))
      expect(importer.data[1][:attributes]).to eq(first: "baz", second: "apa")
    end

    context "with csv_header = true" do
      let(:csv_header) { true }
      it "skips the first row" do
        expect(importer.data).to have(1).items
        expect(importer.data[0][:original_row]).to eq(%w(baz apa))
      end
    end

    context "with parse errors" do
      it "throws an exception containing any errors from the parsed rows" do
        expect {
          KP::Import::DummyRaiser.new(CSV.new(csv), csv_header)
        }.to raise_error(KP::Import::ParseError, "1: foo - foo\tbar\n2: baz - baz\tapa")
      end
    end

    context "with nil results from .attributes_from_row" do
      let(:csv) { "generates,nil,from,.build\nfoo,bar" }
      it "skips the row" do
        expect(importer.data).to have(1).items
        expect(importer.data[0][:original_row]).to eq(%w(foo bar))
      end
    end
  end

  describe ".valid?" do
    let(:csv) { "foo,bar\nfoo,bar" }
    let(:model) { double(:model) }

    it "calls .build for each of the parsed attributes and validates the returned model" do
      model.should_receive(:valid?).twice.and_return(true)
      importer.should_receive(:build).twice.with(first: "foo", second: "bar").and_return(model)
      expect(importer.valid?).to be_true
    end

    it "ignores nil values returned by .build" do
      model.should_receive(:valid?).once.and_return(true)
      importer.should_receive(:build).twice.with(first: "foo", second: "bar").and_return(model, nil)
      expect(importer.valid?).to be_true
    end

    context "with duplicates" do
      let(:csv) { "foo,bar\nfoo,baz" }

      it "ignores duplicates after the first" do
        importer.should_receive(:unique_id).twice.and_return { |a| a[:first] }
        model.should_receive(:valid?).once.and_return(true)
        importer.should_receive(:build).once.with(first: "foo", second: "bar").and_return(model)
        expect(importer.valid?).to be_true
      end
    end
  end

  describe ".invalid_rows" do
    let(:csv) { "foo,bar\nbaz,apa\nbepa,cepa" }

    before(:each) do
      importer.stub(:build).and_return(
        double(:model, :valid? => true),
        double(:model, :valid? => false),
        double(:model, :valid? => true)
      )
    end

    it "includes all invalid rows" do
      expect(importer.valid?).to be_false
      expect(importer.invalid_rows).to eq([
        %w(baz apa)
      ])
    end
  end

  describe ".save!" do
    let(:csv) { "foo,bar\nbaz,apa\nbepa,cepa" }
    let(:model1) { double(:model, valid?: true, new_record?: false, changed?: true) }
    let(:model2) { double(:model, valid?: true, new_record?: true, changed?: true) }
    let(:model3) { double(:model, valid?: true, new_record?: false, changed?: false) }

    before(:each) do
      importer.stub(:build).and_return(model1, model2, model3)
    end

    it "saves all valid models returned from .build" do
      model1.should_receive(:save!).once
      model2.should_receive(:save!).once
      model3.should_receive(:save!).once
      expect(importer.import!).to eq(new: 1, updated: 1, unchanged: 1)
    end

    context "with invalid models" do
    let(:model2) { double(:model, :valid? => false) }
      it "does not save anything" do
        model1.should_not_receive(:save!)
        model2.should_not_receive(:save!)
        model3.should_not_receive(:save!)
        expect(importer.import!).to be_false
      end
    end
  end
end
