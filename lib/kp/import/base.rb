module KP
  module Import

    class ParseError < ::StandardError
    end

    # This is the base class for importers. The data import is based on CSV (or TSV)
    # files. The main flow for importing a file is:
    #
    #   1. Parse the file
    #   2. Validate the data
    #   3. Save to database
    #
    # In order to create an importer, inherit this class and define the following methods:
    #
    #   * +.attributes_from_row+
    #   * +.unique_id+
    #   * +.build+
    #
    # See below for their definition
    class Base

      # Parses the CSV file, skipping any rows that should
      # be skipped, along with the CSV header if defined.
      #
      # Raises a ParseError if one or more rows could not be
      # parsed.
      def initialize(csv, csv_header = false)
        @data = []
        @processed = []

        errors = []
        row_number = 0

        csv.each do |row|
          row_number += 1

          # Skip header row
          if csv_header
            csv_header = false
            next
          end

          begin
            attributes = attributes_from_row(row)
            next unless attributes

            @data << {
              attributes: attributes,
              original_row: row
            }
          rescue ParseError => e
            errors << "#{row_number}: #{e.message} - #{row.join("\t")}"
          end
        end

        # Raise all ParseErrors as a single ParseError
        raise ParseError.new(errors.join("\n")) unless errors.blank?
      end

      # Contains the parsed data as hashes with :attributes
      # and :original_row
      attr_accessor :data

      # Returns a hash with parsed attributes for a CSV row.
      # Raise a +ParseError+ if the row is invalid.
      # Return nil if you want to skip the row
      def attributes_from_row(row)
        raise "Override me!"
      end

      # Defines a unique identifier from the attributes. This is used in
      # the base class to detect duplicates. If nil is returned, no duplicate
      # check is done
      def unique_id(attributes)
        raise "Override me!"
      end

      # Create a new model, or update an existing in this method
      # based on the incoming attributes
      def build(attributes)
        raise "Override me!"
      end

      # Builds models and validates them. Also handles checks
      # for duplicates.
      def valid?
        return @invalid_rows.blank? unless @invalid_rows.nil?

        @valid = []
        @invalid_rows = []

        @data.each do |d|
          attributes = d[:attributes]

          uniq_id = unique_id(attributes)

          # Do not process duplicates
          if uniq_id
            next if @processed.include?(uniq_id)
            @processed << uniq_id
          end

          model = build(attributes)

          # Ignore nil returned from build
          next unless model

          if model.valid?
            @valid << model
          else
            @invalid_rows << d[:original_row]
          end
        end

        return @invalid_rows.blank?
      end

      # Contains any rows which generated an invalid model
      attr_reader :invalid_rows

      # Performs the actual import of data,
      # returning a status hash of new, updated and unchanged models
      def import!
        return false unless valid?

        result = {
          new: 0,
          updated: 0,
          unchanged: 0
        }

        before_import(result) if respond_to?(:before_import)

        @valid.each do |model|
          if model.new_record?
            result[:new] +=1
          elsif model.changed?
            result[:updated] +=1
          else
            result[:unchanged] +=1
          end

          model.save!
        end

        after_import(result) if respond_to?(:after_import)

        return result
      end
    end
  end
end
