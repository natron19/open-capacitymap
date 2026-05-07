require "rails_helper"

RSpec.describe "ProjectIdeas", type: :request do
  let(:user) { create(:user) }

  describe "authentication" do
    it "redirects GET /project_ideas to sign in when not authenticated" do
      get project_ideas_path
      expect(response).to redirect_to(sign_in_path)
    end
  end

  describe "GET /project_ideas" do
    before { sign_in_as(user) }

    it "returns 200 when the user has no projects" do
      get project_ideas_path
      expect(response).to have_http_status(:ok)
    end

    it "lists only the current user's projects" do
      inventory       = create(:gift_inventory, user: user)
      own_idea        = create(:project_idea, gift_inventory: inventory, name: "My Project")
      other_inventory = create(:gift_inventory)
      _other_idea     = create(:project_idea, gift_inventory: other_inventory, name: "Other Project")

      get project_ideas_path
      expect(response.body).to include("My Project")
      expect(response.body).not_to include("Other Project")
    end
  end

  describe "GET /project_ideas/:id" do
    before { sign_in_as(user) }

    it "returns 404 for another user's project" do
      other_inventory = create(:gift_inventory)
      other_idea      = create(:project_idea, gift_inventory: other_inventory)
      get project_idea_path(other_idea)
      expect(response).to have_http_status(:not_found)
    end

    it "renders the show page for the user's own project" do
      inventory = create(:gift_inventory, user: user)
      idea      = create(:project_idea, gift_inventory: inventory)
      get project_idea_path(idea)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(idea.name)
    end
  end

  describe "DELETE /project_ideas/:id" do
    before { sign_in_as(user) }

    it "destroys the user's own project and redirects" do
      inventory = create(:gift_inventory, user: user)
      idea      = create(:project_idea, gift_inventory: inventory)
      expect { delete project_idea_path(idea) }.to change(ProjectIdea, :count).by(-1)
      expect(response).to redirect_to(project_ideas_path)
    end

    it "returns 404 for another user's project" do
      other_inventory = create(:gift_inventory)
      other_idea      = create(:project_idea, gift_inventory: other_inventory)
      delete project_idea_path(other_idea)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /project_ideas/download" do
    before { sign_in_as(user) }

    it "returns a markdown attachment containing the user's project names" do
      inventory = create(:gift_inventory, user: user)
      create(:project_idea, gift_inventory: inventory, name: "My Unique Project Name")
      get download_project_ideas_path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to include("text/markdown")
      expect(response.body).to include("My Unique Project Name")
    end

    it "does not include another user's projects" do
      other_inventory = create(:gift_inventory)
      create(:project_idea, gift_inventory: other_inventory, name: "Other Person Project")
      get download_project_ideas_path
      expect(response.body).not_to include("Other Person Project")
    end
  end
end
