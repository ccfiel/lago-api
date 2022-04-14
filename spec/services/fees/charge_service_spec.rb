# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Fees::ChargeService do
  subject(:charge_subscription_service) do
    described_class.new(invoice: invoice, charge: charge)
  end

  let(:subscription) { create(:subscription) }
  let(:invoice) { create(:invoice, subscription: subscription) }
  let(:billable_metric) { create(:billable_metric, aggregation_type: 'count_agg') }
  let(:charge) { create(:one_time_charge, plan: subscription.plan, charge_model: 'standard') }

  describe '.create' do
    it 'creates a fee' do
      result = charge_subscription_service.create

      expect(result).to be_success

      created_fee = result.fee

      aggregate_failures do
        expect(created_fee.id).not_to be_nil
        expect(created_fee.invoice_id).to eq(invoice.id)
        expect(created_fee.charge_id).to eq(charge.id)
        expect(created_fee.amount_cents).to eq(0)
        expect(created_fee.amount_currency).to eq('EUR')
        expect(created_fee.vat_amount_cents).to eq(0)
        expect(created_fee.vat_rate).to eq(20.0)
      end
    end

    context 'when fee already exists on the period' do
      before do
        create(
          :fee,
          charge: charge,
          subscription: subscription,
          invoice: invoice,
        )
      end

      it 'does not create a new fee' do
        expect { charge_subscription_service.create }.not_to change(Fee, :count)
      end
    end
  end
end