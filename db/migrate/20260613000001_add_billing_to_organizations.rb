class AddBillingToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :stripe_customer_id, :string
    add_column :organizations, :balance_microcents, :bigint, default: 0, null: false
    add_column :organizations, :sms_markup_bps, :integer, default: 0, null: false
    add_column :organizations, :auto_recharge_enabled, :boolean, default: false, null: false
    add_column :organizations, :auto_recharge_threshold_microcents, :bigint
    add_column :organizations, :auto_recharge_amount_microcents, :bigint
    add_index :organizations, :stripe_customer_id, unique: true
  end
end
