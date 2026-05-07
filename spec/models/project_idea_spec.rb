require "rails_helper"

RSpec.describe ProjectIdea, type: :model do
  describe "factory" do
    it "produces a valid record" do
      expect(build(:project_idea)).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a gift_inventory" do
      idea = build(:project_idea)
      expect(idea.gift_inventory).to be_a(GiftInventory)
    end
  end

  describe "has_one :user through :gift_inventory" do
    it "returns the correct user" do
      user      = create(:user)
      inventory = create(:gift_inventory, user: user)
      idea      = create(:project_idea, gift_inventory: inventory)
      expect(idea.user).to eq(user)
    end
  end

  describe "presence validations" do
    it "rejects a blank name" do
      expect(build(:project_idea, name: "")).not_to be_valid
    end

    it "rejects a blank description" do
      expect(build(:project_idea, description: "")).not_to be_valid
    end

    it "rejects a blank first_step" do
      expect(build(:project_idea, first_step: "")).not_to be_valid
    end
  end

  describe "name length" do
    it "accepts a 120-character name" do
      expect(build(:project_idea, name: "a" * 120)).to be_valid
    end

    it "rejects a 121-character name" do
      expect(build(:project_idea, name: "a" * 121)).not_to be_valid
    end
  end

  describe ".ordered scope" do
    it "returns records sorted by position ascending" do
      inventory = create(:gift_inventory)
      third  = create(:project_idea, gift_inventory: inventory, position: 3)
      first  = create(:project_idea, gift_inventory: inventory, position: 1)
      second = create(:project_idea, gift_inventory: inventory, position: 2)
      expect(inventory.project_ideas.ordered.to_a).to eq([first, second, third])
    end
  end

  describe "#gifts_used_list" do
    it "parses the JSON field into an array of hashes" do
      gifts = [{ "category" => "skill", "name" => "facilitation" }]
      idea  = build(:project_idea, gifts_used: gifts.to_json)
      expect(idea.gifts_used_list).to eq(gifts)
    end

    it "returns an empty array when gifts_used is nil" do
      idea = build(:project_idea, gifts_used: nil)
      expect(idea.gifts_used_list).to eq([])
    end
  end
end
