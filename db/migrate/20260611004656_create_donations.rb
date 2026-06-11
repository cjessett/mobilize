class CreateDonations < ActiveRecord::Migration[8.1]
  def change
    create_table :donations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "usd"
      t.string :source
      t.datetime :donated_at, null: false

      t.timestamps
    end
    add_index :donations, [ :organization_id, :donated_at ]

    add_column :organizations, :webhook_token, :string
    add_index :organizations, :webhook_token, unique: true
  end
end
