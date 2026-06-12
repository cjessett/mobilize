class AddInstagramUsernameToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :instagram_username, :string
  end
end
