class CreateProjectIdeas < ActiveRecord::Migration[8.1]
  def change
    create_table :project_ideas, id: :uuid do |t|
      t.references :gift_inventory,  null: false, foreign_key: true, type: :uuid
      t.string     :name,            null: false
      t.text       :description,     null: false
      t.text       :gifts_used
      t.string     :time_commitment
      t.string     :impact_type
      t.text       :first_step,      null: false
      t.text       :gemini_raw
      t.integer    :position
      t.timestamps null: false
    end
  end
end
