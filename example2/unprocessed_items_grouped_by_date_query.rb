# frozen_string_literal: true

module BillingScheduleItems
  class UnprocessedItemsGroupedByDateQuery
    include Callable

    DEFAULT_LIMIT = 5

    def initialize(subscription:, item:, limit: DEFAULT_LIMIT)
      @subscription = subscription
      @item = item
      @limit = limit
    end

    def call
      query
        .map do |row|
          row = row.attributes
          row["components"] = parse_json_data(row["components_json"])
          row["products"] = parse_json_data(row["products_json"])

          row.delete("id")
          row.delete("components_json")
          row.delete("products_json")

          row.with_indifferent_access
        end
    end

    private

    attr_reader :subscription, :item, :limit

    def query
      subscription
        .items
        .select(
          "cast(items.assess_at as date) as billing_date",
          "JSON_ARRAYAGG(
            JSON_OBJECT(
              'id', components.id,
              'name', components.name,
              'type', components.type
            )
          ) as components_json",
          "JSON_ARRAYAGG(
            JSON_OBJECT(
              'id', products.id,
              'name', products.name
            )
          ) as products_json"
        )
        .pending
        .where(period_starts_at: Time.zone.today..)
        .where.not(item: item)
        .left_joins(:component, :product)
        .order(:billing_date)
        .group(:billing_date)
        .limit(limit)
    end

    def parse_json_data(data)
      JSON
        .parse(data)
        .reject { |record| record["id"].nil? }
        .uniq
    end
  end
end
