class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :profile_type, null: false
      t.string :name, null: false
      t.text :bio
      t.string :city, null: false
      t.string :music_genre
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.boolean :map_visible, null: false, default: true

      t.timestamps
    end

    add_index :profiles, :profile_type
    add_index :profiles, :map_visible
    add_index :profiles, [ :latitude, :longitude ]
  end
end
