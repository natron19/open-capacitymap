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
