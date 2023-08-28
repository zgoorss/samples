# frozen_string_literal: true

require "rails_helper"

describe BillingScheduleItems::UnprocessedItemsGroupedByDateQuery do
  include BillingScheduleItemsHelper

  subject { described_class.call(subscription: subscription, item: component_item1) }

  let!(:subscription) { create(:subscription) }
  let!(:component_item1) { create(:component) }
  let!(:component_item2) { create(:component) }
  let!(:component_item3) { create(:component) }

  it "returns grouped by billing date items" do
    expect(subject).to eq(
      [
        {
          "billing_date" => ChargifyTime.advance(Time.current, 1, :month).to_date,
          "components" => [
            { "id" => component_item2.id, "name" => component_item2.name, "type" => component_item2.type },
            { "id" => component_item3.id, "name" => component_item3.name, "type" => component_item3.type },
          ],
          "products" => [
            { "id" => subscription.product.id, "name" => subscription.product.name },
          ],
        },
        {
          "billing_date" => ChargifyTime.advance(Time.current, 2, :month).to_date,
          "components" => [
            { "id" => component_item2.id, "name" => component_item2.name, "type" => component_item2.type },
            { "id" => component_item3.id, "name" => component_item3.name, "type" => component_item3.type },
          ],
          "products" => [
            { "id" => subscription.product.id, "name" => subscription.product.name },
          ],
        },
      ]
    )
  end
end
