class AddVariantsAndEmailTemplates < ActiveRecord::Migration[8.1]
  def change
    add_column :blasts, :variants, :json, null: false, default: {}
    add_column :sms_templates, :variants, :json, null: false, default: {}
    add_reference :sms_templates, :event, foreign_key: true

    create_table :email_templates do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :subject

      t.timestamps
    end
  end
end
