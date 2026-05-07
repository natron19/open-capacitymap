class GiftInventoriesController < ApplicationController
  before_action :set_inventory, only: [:show, :edit, :update, :generate]
  rate_limit to: 5, within: 1.minute, only: [:generate]

  def current
    if current_user.gift_inventory
      redirect_to gift_inventory_path(current_user.gift_inventory)
    else
      redirect_to new_gift_inventory_path
    end
  end

  def new
    @inventory = GiftInventory.new
  end

  def create
    @inventory = current_user.build_gift_inventory(inventory_params)
    if @inventory.save
      redirect_to gift_inventory_path(@inventory), notice: "Inventory saved."
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    @project_ideas = @inventory.project_ideas.ordered
  end

  def edit; end

  def update
    if @inventory.update(inventory_params)
      redirect_to gift_inventory_path(@inventory), notice: "Inventory updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def generate
    variables = {
      skills:               @inventory.skills_list.join(", "),
      interests:            @inventory.interests_list.join(", "),
      weekly_hours:         @inventory.weekly_hours.to_s,
      connections:          @inventory.connections_list.join(", "),
      experience_areas:     @inventory.experience_areas_list.join(", "),
      organization_context: @inventory.organization_context
    }

    raw      = GeminiService.generate(template: "capacitymap_projects_v1", variables:,
                                       response_mime_type: "application/json")
    data     = JSON.parse(raw)
    projects = data["projects"]

    unless projects.is_a?(Array) && projects.length.between?(5, 7)
      return redirect_to @inventory, alert: "The AI returned an unexpected format. Please try again."
    end

    ActiveRecord::Base.transaction do
      @inventory.project_ideas.destroy_all
      projects.each.with_index(1) do |proj, i|
        @inventory.project_ideas.create!(
          name:            proj["name"],
          description:     proj["description"],
          gifts_used:      proj["gifts_used"].to_json,
          time_commitment: proj["time_commitment"],
          impact_type:     proj["impact_type"],
          first_step:      proj["first_step"],
          gemini_raw:      raw,
          position:        i
        )
      end
    end

    redirect_to @inventory, notice: "Projects generated successfully."

  rescue JSON::ParserError
    redirect_to @inventory, alert: "The AI returned an unexpected format. Please try again."
  rescue GeminiService::BudgetExceededError
    redirect_to @inventory, alert: "Daily generation limit reached. Try again tomorrow."
  rescue GeminiService::GatekeeperError
    redirect_to @inventory, alert: "Your inventory content was flagged. Please review and try again."
  rescue GeminiService::TimeoutError
    redirect_to @inventory, alert: "The AI took too long to respond. Please try again."
  rescue GeminiService::GeminiError
    redirect_to @inventory, alert: "An error occurred generating projects. Please try again."
  end

  private

  def set_inventory
    @inventory = current_user.gift_inventory
    unless @inventory && @inventory.id.to_s == params[:id]
      render file: Rails.public_path.join("404.html"), status: :not_found
    end
  end

  def inventory_params
    params.require(:gift_inventory).permit(
      :skills, :interests, :weekly_hours, :connections,
      :experience_areas, :organization_context
    )
  end
end
