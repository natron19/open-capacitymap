require "rails_helper"

RSpec.describe GiftInventory, type: :model do
  describe "factory" do
    it "produces a valid record" do
      expect(build(:gift_inventory)).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a user" do
      inventory = build(:gift_inventory)
      expect(inventory.user).to be_a(User)
    end

    it "has many project_ideas" do
      inventory = create(:gift_inventory)
      create(:project_idea, gift_inventory: inventory)
      expect(inventory.project_ideas.count).to eq(1)
    end
  end

  describe "dependent: :destroy" do
    it "destroys associated project_ideas when the inventory is destroyed" do
      inventory = create(:gift_inventory)
      create(:project_idea, gift_inventory: inventory)
      expect { inventory.destroy }.to change(ProjectIdea, :count).by(-1)
    end
  end

  describe "uniqueness of user_id" do
    it "allows one inventory per user" do
      inventory = create(:gift_inventory)
      expect(inventory).to be_valid
    end

    it "rejects a second inventory for the same user" do
      user = create(:user)
      create(:gift_inventory, user: user)
      duplicate = build(:gift_inventory, user: user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end
  end

  describe "weekly_hours validation" do
    it "accepts 1" do
      expect(build(:gift_inventory, weekly_hours: 1)).to be_valid
    end

    it "accepts 80" do
      expect(build(:gift_inventory, weekly_hours: 80)).to be_valid
    end

    it "rejects 0" do
      expect(build(:gift_inventory, weekly_hours: 0)).not_to be_valid
    end

    it "rejects 81" do
      expect(build(:gift_inventory, weekly_hours: 81)).not_to be_valid
    end
  end

  describe "organization_context length" do
    it "rejects a string under 50 characters" do
      expect(build(:gift_inventory, organization_context: "a" * 49)).not_to be_valid
    end

    it "accepts exactly 50 characters" do
      expect(build(:gift_inventory, organization_context: "a" * 50)).to be_valid
    end
  end

  describe "skills count" do
    it "accepts 5 skills" do
      expect(build(:gift_inventory, skills: ["a", "b", "c", "d", "e"].to_json)).to be_valid
    end

    it "accepts 8 skills" do
      expect(build(:gift_inventory, skills: ("a".."h").to_a.to_json)).to be_valid
    end

    it "rejects 4 skills" do
      expect(build(:gift_inventory, skills: ["a", "b", "c", "d"].to_json)).not_to be_valid
    end

    it "rejects 9 skills" do
      expect(build(:gift_inventory, skills: ("a".."i").to_a.to_json)).not_to be_valid
    end
  end

  describe "interests count" do
    it "accepts 3 interests" do
      expect(build(:gift_inventory, interests: ["a", "b", "c"].to_json)).to be_valid
    end

    it "accepts 5 interests" do
      expect(build(:gift_inventory, interests: ["a", "b", "c", "d", "e"].to_json)).to be_valid
    end

    it "rejects 2 interests" do
      expect(build(:gift_inventory, interests: ["a", "b"].to_json)).not_to be_valid
    end

    it "rejects 6 interests" do
      expect(build(:gift_inventory, interests: ["a", "b", "c", "d", "e", "f"].to_json)).not_to be_valid
    end
  end

  describe "connections count" do
    it "accepts 3 connections" do
      expect(build(:gift_inventory, connections: ["a", "b", "c"].to_json)).to be_valid
    end

    it "rejects 2 connections" do
      expect(build(:gift_inventory, connections: ["a", "b"].to_json)).not_to be_valid
    end

    it "rejects 6 connections" do
      expect(build(:gift_inventory, connections: ["a", "b", "c", "d", "e", "f"].to_json)).not_to be_valid
    end
  end

  describe "experience_areas count" do
    it "accepts 1 experience area" do
      expect(build(:gift_inventory, experience_areas: ["community organizing"].to_json)).to be_valid
    end

    it "rejects an empty array" do
      expect(build(:gift_inventory, experience_areas: [].to_json)).not_to be_valid
    end
  end

  describe "#skills_list" do
    it "returns a Ruby array from JSON-encoded text" do
      inventory = build(:gift_inventory, skills: ["facilitation", "copywriting"].to_json)
      expect(inventory.skills_list).to eq(["facilitation", "copywriting"])
    end
  end

  describe "#skills_list=" do
    it "accepts an array and stores it as JSON" do
      inventory = build(:gift_inventory)
      inventory.skills_list = ["a", "b", "c", "d", "e"]
      expect(inventory.skills).to eq(["a", "b", "c", "d", "e"].to_json)
    end

    it "passes a JSON string through unchanged" do
      inventory = build(:gift_inventory)
      json = ["a", "b", "c", "d", "e"].to_json
      inventory.skills_list = json
      expect(inventory.skills).to eq(json)
    end
  end
end
