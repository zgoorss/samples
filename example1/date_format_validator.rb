# frozen_string_literal: true

class DateFormatValidator
  class MinDateError < StandardError; end

  include ActiveModel::Validations

  MAX_DATE = "3000-12-31 23:59:59".freeze
  ISO_ERROR_MSG = "supplied value is invalid, expected ISO 8601 format".freeze
  MIN_DATE_ERROR_MSG = "must be greater than or equal to".freeze

  def initialize(param_name:, param_value:, min_date: Time.zone.today, require_iso8601: true)
    @param_name = param_name
    @param_value = param_value
    @min_date = min_date
    @require_iso8601 = require_iso8601
    @errors = ActiveModel::Errors.new(self)
  end

  def call
    begin
      validate_with_iso8601
      validate_with_dry_schema
      validate_min_date
    rescue StandardError => e
      errors.add(param_name, "#{param_name.to_s.humanize}: #{e.message}")
    end

    self
  end

  def self.validate(...)
    new(...).call
  end

  def success?
    errors.blank?
  end

  attr_reader :param_name, :param_value, :min_date, :require_iso8601, :errors

  private

  def validate_with_dry_schema
    result = dry_schema.call({ param_name => param_value })
    raise ArgumentError, result.errors[param_name][0] if result.failure?
  end

  def dry_schema
    param = param_name

    Dry::Schema.Params do
      config.messages.namespace = :api_errors

      optional(param).filled(:date_time, lteq?: MAX_DATE)
    end
  end

  def validate_with_iso8601
    return if !require_iso8601

    DateTime.iso8601(param_value)
  rescue Date::Error, TypeError => e
    raise e, ISO_ERROR_MSG
  end

  # As we want to be sure that there will be no zone issues,
  # we need to have the correct date provided explicitly.
  def validate_min_date
    return if min_date.nil?

    result = Date.parse(param_value.to_s) >= Date.parse(min_date.to_s)
    return if result

    raise MinDateError, "#{MIN_DATE_ERROR_MSG} #{min_date.to_date}"
  end
end
