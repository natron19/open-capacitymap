class CreateGiftInventories < ActiveRecord::Migration[8.1]
  def change
    create_table :gift_inventories, id: :uuid do |t|
      t.references :user,                 null: false, foreign_key: true, type: :uuid
      t.text       :skills,               null: false, default: "[]"
      t.text       :interests,            null: false, default: "[]"
      t.integer    :weekly_hours,         null: false
      t.text       :connections,          null: false, default: "[]"
      t.text       :experience_areas,     null: false, default: "[]"
      t.text       :organization_context, null: false
      t.timestamps null: false
    end
  end
end
