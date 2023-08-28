# frozen_string_literal: true

require "rails_helper"

describe DateFormatValidator do
  describe ".validate" do
    subject do
      described_class.validate(
        param_name: :initial_billing_at,
        param_value: initial_billing_at,
        require_iso8601: require_iso8601,
        min_date: min_date
      )
    end

    let(:require_iso8601) { true }
    let(:min_date) { "2019-01-01" }

    context "when min_date is nil" do
      let(:min_date) { nil }

      context "when passing any date in the past" do
        let(:initial_billing_at) { "2015-02-02" }

        it "returns success" do
          expect(subject.success?).to eq(true)
        end
      end
    end

    context "when require_iso8601 is false" do
      let(:require_iso8601) { false }

      context "when passing invalid with iso8601 time" do
        let(:initial_billing_at) { "2022-07-15T14:24:46-dfsfds:00" }

        it "returns success" do
          expect(subject.success?).to eq(true)
        end
      end

      context "when error is raised from the underyling library" do
        let(:initial_billing_at) { "2022-09-15T04:24:46-04655756:00" }

        before do
          dry_schema_double = double
          allow(dry_schema_double).to receive(:call).and_raise(RangeError, "Out of Cheese Error")
          allow_any_instance_of(described_class).to receive(:dry_schema).and_return(dry_schema_double)
        end

        it "rescues and reports the error" do
          expect(subject.errors.messages[:initial_billing_at]).to eq(
            ["Initial billing at: Out of Cheese Error"]
          )
        end
      end
    end

    context "when passing valid date" do
      let(:initial_billing_at) { "2019-02-02" }

      it "returns success" do
        expect(subject.success?).to eq(true)
      end
    end

    context "when passing date is earlier than min_date" do
      let(:initial_billing_at) { "2018-12-31" }

      it "returns errors" do
        expect(subject.errors.messages[:initial_billing_at]).to eq(
          ["Initial billing at: must be greater than or equal to 2019-01-01"]
        )
      end
    end

    context "when passing date is earlier than min_date in different time zones" do
      let(:min_date) { DateTime.parse("2019-01-01").utc }
      let(:initial_billing_at) { DateTime.parse("2018-12-31T23:24:46-04:00").iso8601 }

      it "returns errors" do
        expect(subject.errors.messages[:initial_billing_at]).to eq(
          ["Initial billing at: must be greater than or equal to 2019-01-01"]
        )
      end
    end

    context "when passing supplied value is invalid, expected ISO 8601 format" do
      let(:initial_billing_at) { "2019-02-31" }

      it "returns errors" do
        expect(subject.errors.messages[:initial_billing_at]).to eq(
          ["Initial billing at: supplied value is invalid, expected ISO 8601 format"]
        )
      end
    end

    context "when passing valid time" do
      let(:initial_billing_at) { "2019-02-02T14:24:46-04:00" }

      it "returns success" do
        expect(subject.success?).to eq(true)
      end
    end

    context "when passing invalid time" do
      let(:initial_billing_at) { "2019-02-31T14:24:46-04:00" }

      it "returns errors" do
        expect(subject.errors.messages[:initial_billing_at]).to eq(
          ["Initial billing at: supplied value is invalid, expected ISO 8601 format"]
        )
      end
    end

    context "when passing time with gibberish inside #1" do
      let(:initial_billing_at) { "2022-07-15T14:vfvf:46-04:00" }

      it "returns errors" do
        expect(subject.errors.messages[:initial_billing_at]).to eq(
          ["Initial billing at: supplied value is invalid, expected ISO 8601 format"]
        )
      end
    end

    context "when passing time with gibberish inside #2" do
      let(:initial_billing_at) { "2022-07-15Tfgdfg:24:46-04:00" }

      it "returns errors" do
        expect(subject.errors.messages[:initial_billing_at]).to eq(
          ["Initial billing at: supplied value is invalid, expected ISO 8601 format"]
        )
      end
    end

    context "when passing time with gibberish inside #3" do
      let(:initial_billing_at) { "2022-07-15T14:24:fgffh-04:00" }

      it "returns errors" do
        expect(subject.errors.messages[:initial_billing_at]).to eq(
          ["Initial billing at: supplied value is invalid, expected ISO 8601 format"]
        )
      end
    end

    context "when passing time with gibberish inside #4" do
      let(:initial_billing_at) { "2022-07-15T14:24:46-dfsfds:00" }

      it "returns errors" do
        expect(subject.errors.messages[:initial_billing_at]).to eq(
          ["Initial billing at: supplied value is invalid, expected ISO 8601 format"]
        )
      end
    end

    context "when passing time with gibberish inside #5" do
      let(:initial_billing_at) { "2022-07-15T14:24:46-04:fbgfb" }

      it "returns errors" do
        expect(subject.errors.messages[:initial_billing_at]).to eq(
          ["Initial billing at: supplied value is invalid, expected ISO 8601 format"]
        )
      end
    end

    context "when passing year larger than 3000" do
      let(:initial_billing_at) { "3001-02-31" }

      it "returns errors" do
        expect(subject.errors.messages[:initial_billing_at]).to eq(
          ["Initial billing at: supplied value is invalid, expected ISO 8601 format"]
        )
      end
    end

    context "when passing nil" do
      let(:initial_billing_at) { nil }

      it "returns errors" do
        expect(subject.errors.messages[:initial_billing_at]).to eq(
          ["Initial billing at: supplied value is invalid, expected ISO 8601 format"]
        )
      end
    end
  end
end
