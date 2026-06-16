class CreateLedgerEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :ledger_entries do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :message, null: true, foreign_key: true
      t.string :entry_type, null: false
      t.bigint :amount_microcents, null: false
      t.bigint :balance_after_microcents, null: false
      t.string :stripe_payment_intent_id
      t.string :description

      t.timestamps
    end
  end
end
