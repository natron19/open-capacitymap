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
      skills       { ["a", "b", "c", "d", "e"].to_json }
      interests    { ["x", "y", "z"].to_json }
      connections  { ["c1", "c2", "c3"].to_json }
    end
  end
end
