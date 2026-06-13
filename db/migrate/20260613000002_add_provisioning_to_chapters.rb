class AddProvisioningToChapters < ActiveRecord::Migration[8.1]
  def change
    add_column :chapters, :twilio_sid, :string
    add_column :chapters, :provisioned_at, :datetime
  end
end
