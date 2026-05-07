require "rails_helper"

RSpec.describe "GiftInventories", type: :request do
  let(:user)             { create(:user) }
  let(:valid_params) do
    {
      gift_inventory: {
        skills:               ["a", "b", "c", "d", "e"].to_json,
        interests:            ["x", "y", "z"].to_json,
        weekly_hours:         6,
        connections:          ["c1", "c2", "c3"].to_json,
        experience_areas:     ["e1"].to_json,
        organization_context: "A" * 50
      }
    }
  end

  describe "authentication" do
    it "redirects GET /gift_inventories/new to sign in when not authenticated" do
      get new_gift_inventory_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects POST /gift_inventories to sign in when not authenticated" do
      post gift_inventories_path, params: valid_params
      expect(response).to redirect_to(sign_in_path)
    end
  end

  describe "GET /gift_inventories/current" do
    before { sign_in_as(user) }

    it "redirects to new when the user has no inventory" do
      get current_gift_inventories_path
      expect(response).to redirect_to(new_gift_inventory_path)
    end

    it "redirects to the inventory show page when one exists" do
      inventory = create(:gift_inventory, user: user)
      get current_gift_inventories_path
      expect(response).to redirect_to(gift_inventory_path(inventory))
    end
  end

  describe "POST /gift_inventories" do
    before { sign_in_as(user) }

    it "creates the inventory and redirects to show" do
      expect { post gift_inventories_path, params: valid_params }
        .to change(GiftInventory, :count).by(1)
      expect(response).to redirect_to(gift_inventory_path(GiftInventory.last))
    end

    it "returns 422 when skills count is fewer than 5" do
      bad_params = valid_params.deep_merge(
        gift_inventory: { skills: ["a", "b"].to_json }
      )
      post gift_inventories_path, params: bad_params
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /gift_inventories/:id" do
    before { sign_in_as(user) }

    it "returns 404 for another user's inventory" do
      other_inventory = create(:gift_inventory)
      get gift_inventory_path(other_inventory)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /gift_inventories/:id/edit" do
    before { sign_in_as(user) }

    it "returns 404 for another user's inventory" do
      other_inventory = create(:gift_inventory)
      get edit_gift_inventory_path(other_inventory)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /gift_inventories/:id/generate" do
    let(:inventory) { create(:gift_inventory, user: user) }
    let(:valid_gemini_response) do
      { "projects" => Array.new(5) { |i|
        {
          "name"            => "Project #{i + 1}",
          "description"     => "Description of project #{i + 1}.",
          "gifts_used"      => [{ "category" => "skill", "name" => "facilitation" }],
          "time_commitment" => "2 hrs/wk",
          "impact_type"     => "Direct service",
          "first_step"      => "Take one small step."
        }
      } }.to_json
    end

    before { sign_in_as(user) }

    context "with a valid stubbed Gemini response" do
      before { gemini_returns(valid_gemini_response) }

      it "creates 5 ProjectIdea records" do
        post generate_gift_inventory_path(inventory)
        expect(inventory.reload.project_ideas.count).to eq(5)
      end

      it "replaces an existing batch" do
        create_list(:project_idea, 3, gift_inventory: inventory)
        post generate_gift_inventory_path(inventory)
        expect(inventory.reload.project_ideas.count).to eq(5)
      end

      it "redirects to the inventory show page with a notice" do
        post generate_gift_inventory_path(inventory)
        expect(response).to redirect_to(gift_inventory_path(inventory))
        expect(flash[:notice]).to be_present
      end
    end

    context "with malformed JSON from Gemini" do
      before { gemini_returns("not valid json") }

      it "redirects with an alert and creates no ProjectIdea records" do
        post generate_gift_inventory_path(inventory)
        expect(response).to redirect_to(gift_inventory_path(inventory))
        expect(flash[:alert]).to be_present
        expect(inventory.project_ideas.count).to eq(0)
      end
    end

    context "with GeminiService::TimeoutError" do
      before { gemini_raises(GeminiService::TimeoutError) }

      it "redirects with a timeout alert" do
        post generate_gift_inventory_path(inventory)
        expect(response).to redirect_to(gift_inventory_path(inventory))
        expect(flash[:alert]).to match(/too long|try again/i)
      end
    end

    context "with GeminiService::BudgetExceededError" do
      before { gemini_raises(GeminiService::BudgetExceededError) }

      it "redirects with a budget alert" do
        post generate_gift_inventory_path(inventory)
        expect(response).to redirect_to(gift_inventory_path(inventory))
        expect(flash[:alert]).to match(/limit|tomorrow/i)
      end
    end

    it "returns 404 when trying to generate for another user's inventory" do
      other_inventory = create(:gift_inventory)
      post generate_gift_inventory_path(other_inventory)
      expect(response).to have_http_status(:not_found)
    end
  end
end
