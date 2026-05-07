# Phase 2 — Data Models & Migrations

**Goal:** `GiftInventory` and `ProjectIdea` tables exist, models pass all validations, factories exist, and model specs are green.

---

## Context / Files to Read First

- `docs/open-capacitymap/capacitymap-demo-spec.md` §3 (Data Model)
- `docs/testing.md` — factory conventions, RSpec model spec patterns
- `app/models/user.rb` — where to add `has_one :gift_inventory`
- `db/schema.rb` — confirm UUID PK convention and `pgcrypto` extension is present
- `spec/factories/users.rb` — factory style to mirror

---

## Tasks

### 2.1 — Migration: `gift_inventories`

```ruby
create_table :gift_inventories, id: :uuid do |t|
  t.references :user, null: false, foreign_key: true, type: :uuid, index: true
  t.text :skills,               null: false, default: "[]"
  t.text :interests,            null: false, default: "[]"
  t.integer :weekly_hours,      null: false
  t.text :connections,          null: false, default: "[]"
  t.text :experience_areas,     null: false, default: "[]"
  t.text :organization_context, null: false
  t.timestamps null: false
end
```

### 2.2 — Migration: `project_ideas`

```ruby
create_table :project_ideas, id: :uuid do |t|
  t.references :gift_inventory, null: false, foreign_key: true, type: :uuid, index: true
  t.string :name,              null: false
  t.text   :description,       null: false
  t.text   :gifts_used
  t.string :time_commitment
  t.string :impact_type
  t.text   :first_step,        null: false
  t.text   :gemini_raw
  t.integer :position
  t.timestamps null: false
end
```

### 2.3 — Run the migrations

```bash
rails db:migrate
```

Confirm `db/schema.rb` reflects both tables with UUID PKs.

### 2.4 — `app/models/gift_inventory.rb`

```ruby
class GiftInventory < ApplicationRecord
  belongs_to :user
  has_many :project_ideas, dependent: :destroy

  validates :user_id, uniqueness: true
  validates :weekly_hours, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 80 }
  validates :organization_context, length: { minimum: 50, maximum: 1000 }
  validate :skills_count
  validate :interests_count
  validate :connections_count
  validate :experience_areas_count

  %w[skills interests connections experience_areas].each do |field|
    define_method(:"#{field}_list") { JSON.parse(send(field)) rescue [] }
    define_method(:"#{field}_list=") do |val|
      send(:"#{field}=", val.is_a?(Array) ? val.to_json : val)
    end
  end

  private

  def skills_count
    count = skills_list.length
    errors.add(:skills, "must have between 5 and 8 entries") unless count.between?(5, 8)
  end

  def interests_count
    count = interests_list.length
    errors.add(:interests, "must have between 3 and 5 entries") unless count.between?(3, 5)
  end

  def connections_count
    count = connections_list.length
    errors.add(:connections, "must have between 3 and 5 entries") unless count.between?(3, 5)
  end

  def experience_areas_count
    errors.add(:experience_areas, "must have at least 1 entry") if experience_areas_list.empty?
  end
end
```

### 2.5 — Update `app/models/user.rb`

Add inside the `User` class:

```ruby
has_one :gift_inventory, dependent: :destroy
```

### 2.6 — `app/models/project_idea.rb`

```ruby
class ProjectIdea < ApplicationRecord
  belongs_to :gift_inventory
  has_one :user, through: :gift_inventory

  validates :name, :description, :first_step, presence: true
  validates :name, length: { maximum: 120 }

  scope :ordered,      -> { order(:position) }
  scope :latest_batch, -> { where(created_at: maximum(:created_at).beginning_of_minute..) }

  def gifts_used_list
    JSON.parse(gifts_used || "[]") rescue []
  end
end
```

### 2.7 — `spec/factories/gift_inventories.rb`

```ruby
FactoryBot.define do
  factory :gift_inventory do
    association :user
    skills               { ["facilitation", "copywriting", "event planning",
                            "public speaking", "project management"].to_json }
    interests            { ["local food systems", "civic engagement", "climate adaptation"].to_json }
    weekly_hours         { 6 }
    connections          { ["food co-op board", "neighborhood email list", "former nonprofit colleague"].to_json }
    experience_areas     { ["community organizing", "small-nonprofit ops"].to_json }
    organization_context { "A 120-person neighborhood mutual aid network focused on winter readiness. We run a tool library, a meal-share rotation, and an annual community garden harvest. Members are mostly working-age with a small retiree cohort." }

    trait :minimal do
      skills    { ["a", "b", "c", "d", "e"].to_json }
      interests { ["x", "y", "z"].to_json }
      connections { ["c1", "c2", "c3"].to_json }
    end
  end
end
```

### 2.8 — `spec/factories/project_ideas.rb`

```ruby
FactoryBot.define do
  factory :project_idea do
    association :gift_inventory
    name            { "Neighborhood Skill-Share Night" }
    description     { "A monthly gathering where members teach and learn practical skills. Seed data — not AI generated." }
    gifts_used      { [{ "category" => "skill", "name" => "facilitation" }].to_json }
    time_commitment { "2 to 3 hours per month" }
    impact_type     { "Capacity building" }
    first_step      { "Draft a one-page flyer and share in the neighborhood email list." }
    gemini_raw      { '{"projects":[]}' }
    position        { 1 }
  end
end
```

---

## RSpec

### `spec/models/gift_inventory_spec.rb`

Write a spec covering:

- Factory creates a valid record (`expect(build(:gift_inventory)).to be_valid`).
- `validates :weekly_hours` — rejects 0 and 81, accepts 1 and 80.
- `validates skills count` — rejects 4 items and 9 items, accepts 5 and 8.
- `validates interests count` — rejects 2 and 6, accepts 3 and 5.
- `validates connections count` — rejects 2 and 6.
- `validates experience_areas count` — rejects empty array.
- `validates :organization_context` minimum 50 chars — rejects a 49-char string.
- `validates :user_id, uniqueness: true` — second inventory for same user is invalid.
- `belongs_to :user` and `has_many :project_ideas` associations exist.
- `dependent: :destroy` — destroying the inventory destroys its project ideas.
- `skills_list` returns a Ruby array from a JSON-encoded string.
- `skills_list=` accepts an array and stores it as JSON.

### `spec/models/project_idea_spec.rb`

Write a spec covering:

- Factory creates a valid record.
- `validates :name, :description, :first_step` — each fails when blank.
- `validates :name` length — rejects a 121-char name.
- `belongs_to :gift_inventory` association exists.
- `ordered` scope returns records ascending by `position`.
- `has_one :user, through: :gift_inventory` — `project_idea.user` returns the correct user.
- `gifts_used_list` parses the JSON field into an array of hashes.

---

## Manual Tests

- [ ] Open rails console and `create(:gift_inventory)` with valid data — confirm it saves.
- [ ] Confirm validation error when `skills` has 4 items.
- [ ] Confirm `skills_list` returns an array.
- [ ] Run `bundle exec rspec spec/models/gift_inventory_spec.rb spec/models/project_idea_spec.rb` — all green.

---

## Acceptance Criteria

- [ ] `rails db:migrate` succeeds; both tables appear in `db/schema.rb` with UUID PKs.
- [ ] `GiftInventory` and `ProjectIdea` model files exist with all associations, validations, and helpers.
- [ ] `User` model has `has_one :gift_inventory`.
- [ ] Both factory files exist and produce valid records.
- [ ] All model specs pass (`bundle exec rspec spec/models/`).
