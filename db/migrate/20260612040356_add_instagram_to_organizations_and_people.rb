class AddInstagramToOrganizationsAndPeople < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :instagram_page_id, :string
    add_column :organizations, :instagram_access_token, :string

    add_column :people, :instagram_user_id, :string
    add_index :people, [ :organization_id, :instagram_user_id ], unique: true,
              where: "instagram_user_id IS NOT NULL"
  end
end
