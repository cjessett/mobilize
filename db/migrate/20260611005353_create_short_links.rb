class CreateShortLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :short_links do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :token, null: false
      t.string :destination_url, null: false
      t.references :blast, foreign_key: true
      t.references :message, foreign_key: true
      t.references :person, foreign_key: true

      t.timestamps
    end
    add_index :short_links, :token, unique: true

    create_table :link_clicks do |t|
      t.references :short_link, null: false, foreign_key: true
      t.datetime :clicked_at, null: false
      t.string :user_agent
      t.string :ip

      t.timestamps
    end

    add_column :submissions, :source_blast_id, :integer
    add_index :submissions, :source_blast_id
  end
end
