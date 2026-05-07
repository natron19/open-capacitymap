# Admin user — credentials for local demo use only
User.find_or_create_by!(email: "demo@example.com") do |u|
  u.name                  = "Demo User"
  u.password              = "password123"
  u.password_confirmation = "password123"
  u.admin                 = true
end

puts "Demo user: demo@example.com / password123"

# Health ping template — used by /up/llm
AiTemplate.find_or_create_by!(name: "health_ping") do |t|
  t.description          = "Minimal prompt used by the /up/llm health check endpoint."
  t.system_prompt        = "You are a health check endpoint. Respond with exactly: ok"
  t.user_prompt_template = "ping"
  t.model                = "gemini-2.5-flash"
  t.max_output_tokens    = 10
  t.temperature          = 0.0
  t.notes                = "Do not modify. Used by HealthController#llm."
end

puts "Seeded: health_ping AI template"

# Placeholder demo template — each demo app replaces this
AiTemplate.find_or_create_by!(name: "demo_placeholder_v1") do |t|
  t.description          = "Starter template. Replace with your demo's actual prompt."
  t.system_prompt        = "You are a helpful assistant."
  t.user_prompt_template = "Please help me with: {{request}}"
  t.model                = "gemini-2.5-flash"
  t.max_output_tokens    = 2000
  t.temperature          = 0.7
  t.notes                = "Starter template. Replace this in your demo app's seeds.rb."
end

puts "Seeded: demo_placeholder_v1 AI template"

# CapacityMap Demo — main AI template
AiTemplate.find_or_create_by!(name: "capacitymap_projects_v1") do |t|
  t.description        = "Generates 5 to 7 project ideas tailored to a user's gift inventory and organization context, naming explicitly which gifts each project draws on."
  t.model              = "gemini-2.5-flash"
  t.max_output_tokens  = 2000
  t.temperature        = 0.6
  t.system_prompt      = <<~PROMPT.strip
    You are a community-capacity matching assistant. Your job is to read a person's
    gift inventory and the context of the organization or community they are part
    of, then propose 5 to 7 specific projects where their gifts could be put to
    meaningful use.

    You are operating inside the G.I.F.T. framework: Gather, Invite, Fit, Thank.
    This call corresponds to the Fit step. The contributor has already gathered
    their gifts; you are surfacing projects that fit those gifts well enough that
    the contributor would say yes if invited.

    Treat the user as a gift-bearer, not a resource to deploy. Projects should
    honor what the contributor enjoys doing and the time they have, not maximize
    extraction.

    For each project, you must:
    1. Name the project specifically. Avoid generic titles like "Volunteer
       project" or "Help out at the community center". Use a name a coordinator
       could put on a sign-up sheet.
    2. Write a one-paragraph description that explains what the project is, who
       it serves, and why this contributor in particular is well suited to it.
    3. List which gifts from the inventory the project draws on. Use the exact
       wording the contributor used. Categorize each gift used as one of:
       "skill", "interest", "connection", or "experience_area".
    4. Estimate a realistic time commitment (e.g., "2 to 4 hours per week for 6
       weeks"). Stay within the contributor's stated weekly availability.
    5. Name the type of impact the project creates. Examples: "Direct service",
       "Capacity building", "Storytelling", "Coalition building", "Infrastructure".
    6. Suggest a concrete first step the contributor could take THIS WEEK to
       begin. The first step must be small enough to fit in 30 minutes.

    Constraints:
    - Suggest projects that fit the organization context provided. Do not
      propose projects that contradict the organization's mission or member
      type.
    - Do not propose projects that require more weekly hours than the
      contributor has stated.
    - Do not invent gifts the contributor did not list. Every gift named in
      "gifts_used" must appear in the inventory.
    - Do not promise specific outcomes or impact magnitudes. The contributor
      validates fit by reading and choosing.
    - Output valid JSON only, with no markdown code fences and no commentary.

    Return JSON in exactly this shape:
    {
      "projects": [
        {
          "name": "string",
          "description": "string",
          "gifts_used": [
            {"category": "skill|interest|connection|experience_area", "name": "string"}
          ],
          "time_commitment": "string",
          "impact_type": "string",
          "first_step": "string"
        }
      ]
    }

    The projects array must contain 5 to 7 entries.
  PROMPT
  t.user_prompt_template = <<~PROMPT.strip
    Contributor's gift inventory:

    Skills they enjoy using: {{skills}}
    Interests and causes they care about: {{interests}}
    Weekly availability: {{weekly_hours}} hours per week
    Connections they could activate: {{connections}}
    Experience areas: {{experience_areas}}

    Organization or community context:
    {{organization_context}}

    Suggest 5 to 7 specific projects where this contributor's gifts could be
    applied. Follow the rules in the system instruction. Return JSON only.
  PROMPT
  t.notes = "Temperature 0.6 favors structured output. Watch for: model occasionally returns 4 projects despite the rule (retry usually fixes it); model sometimes invents a skill near-paraphrase (tighten prompt in v2). Test against a narrow organization_context (single-mission food pantry) to confirm the model does not drift into generic suggestions. This demo does not use Gemini function calling — single-shot prompt with structured JSON output."
end

puts "Seeded: capacitymap_projects_v1 AI template"

# Viewer user — no inventory, experiences the empty state
User.find_or_create_by!(email: "viewer@example.com") do |u|
  u.name                  = "Viewer"
  u.password              = "password123"
  u.password_confirmation = "password123"
  u.admin                 = false
end

puts "Viewer user: viewer@example.com / password123"

# Sample GiftInventory and ProjectIdeas for the demo admin
demo = User.find_by!(email: "demo@example.com")

inventory = GiftInventory.find_or_create_by!(user: demo) do |inv|
  inv.skills               = ["facilitation", "copywriting", "event planning",
                               "public speaking", "project management",
                               "basic graphic design"].to_json
  inv.interests            = ["local food systems", "intergenerational community",
                               "climate adaptation", "civic engagement"].to_json
  inv.weekly_hours         = 6
  inv.connections          = ["local food co-op board", "neighborhood email list",
                               "two former colleagues at regional nonprofits"].to_json
  inv.experience_areas     = ["small-nonprofit operations", "community organizing", "education"].to_json
  inv.organization_context = "I am part of a 120-person neighborhood mutual aid network in a small city. Our current focus is winter readiness: we run a tool library, a meal-share rotation, and an annual community garden harvest. Members are mostly working-age, with a small but active retiree cohort. We meet monthly and coordinate via email plus a chat thread."
end

puts "Seeded: GiftInventory for demo@example.com"

if inventory.project_ideas.empty?
  SEED_RAW = '{"projects":[]}'.freeze

  [
    {
      position:        1,
      name:            "Neighborhood Skill-Share Workshop",
      description:     "Seed data — not AI generated. A recurring monthly workshop where mutual aid network members teach each other practical skills. You would plan and facilitate each session, handle logistics, and design simple promotional materials. Your background in community organizing makes you well suited to keep the tone collaborative rather than instructional.",
      gifts_used:      [
        { "category" => "skill",    "name" => "facilitation" },
        { "category" => "skill",    "name" => "event planning" },
        { "category" => "skill",    "name" => "basic graphic design" },
        { "category" => "interest", "name" => "intergenerational community" }
      ].to_json,
      time_commitment: "3 hrs/wk for 8 weeks",
      impact_type:     "Capacity building",
      first_step:      "Draft a one-page workshop concept and share it with the monthly meeting coordinator this week."
    },
    {
      position:        2,
      name:            "Winter Readiness Newsletter",
      description:     "Seed data — not AI generated. A seasonal email newsletter sent to the 120-person network before winter, covering tool library hours, meal-share sign-ups, and mutual aid resources. You would write and design each issue. Your copywriting skill and community organizing experience make you the right person to strike the tone: warm, specific, and action-oriented.",
      gifts_used:      [
        { "category" => "skill",    "name" => "copywriting" },
        { "category" => "skill",    "name" => "basic graphic design" },
        { "category" => "interest", "name" => "local food systems" },
        { "category" => "experience_area", "name" => "community organizing" }
      ].to_json,
      time_commitment: "2 hrs/wk for 6 weeks",
      impact_type:     "Storytelling",
      first_step:      "Write a one-paragraph draft of the newsletter intro and send it to one trusted network member for feedback."
    },
    {
      position:        3,
      name:            "Tool Library Intake Coordinator",
      description:     "Seed data — not AI generated. Own the onboarding process for new tool library borrowers: a short intake form, a welcome email, and a 15-minute walkthrough of borrowing terms. Your project management skill and small-nonprofit operations background mean you can build the intake process once and hand it off cleanly to future volunteers.",
      gifts_used:      [
        { "category" => "skill",            "name" => "project management" },
        { "category" => "experience_area",  "name" => "small-nonprofit operations" },
        { "category" => "connection",       "name" => "neighborhood email list" }
      ].to_json,
      time_commitment: "1 to 2 hrs/wk",
      impact_type:     "Direct service",
      first_step:      "Map the current intake steps on a single sheet of paper so you can see what is missing."
    },
    {
      position:        4,
      name:            "Mutual Aid Network Mapping Project",
      description:     "Seed data — not AI generated. A visual map of the network's resources, gaps, and member skills — updated annually and shared at the monthly meeting. You would design the data collection form, analyze responses, and present findings. Your experience in community organizing and your connections to regional nonprofits give you the perspective to see what the map should surface.",
      gifts_used:      [
        { "category" => "skill",       "name" => "project management" },
        { "category" => "skill",       "name" => "public speaking" },
        { "category" => "connection",  "name" => "two former colleagues at regional nonprofits" },
        { "category" => "experience_area", "name" => "community organizing" }
      ].to_json,
      time_commitment: "4 to 6 hrs total over 4 weeks",
      impact_type:     "Infrastructure",
      first_step:      "Write five questions you would want the network mapping survey to answer."
    },
    {
      position:        5,
      name:            "New Member Welcome Interview Program",
      description:     "Seed data — not AI generated. A short one-on-one welcome call with each new network member in their first month. You ask three questions, listen, and connect them with one existing member who shares their interest. Your facilitation skill and interest in intergenerational community make these calls feel like a conversation rather than a form.",
      gifts_used:      [
        { "category" => "skill",    "name" => "facilitation" },
        { "category" => "skill",    "name" => "public speaking" },
        { "category" => "interest", "name" => "intergenerational community" },
        { "category" => "interest", "name" => "civic engagement" }
      ].to_json,
      time_commitment: "1 hr/wk",
      impact_type:     "Capacity building",
      first_step:      "Draft the three welcome interview questions and test them in a conversation with one current member."
    },
    {
      position:        6,
      name:            "Annual Harvest Event Planner",
      description:     "Seed data — not AI generated. Own the planning and day-of coordination for the network's annual community garden harvest. You handle the run-of-show, volunteer assignments, and the post-event writeup. Your event planning and copywriting skills plus your connection to the local food co-op board make you well positioned to grow attendance year over year.",
      gifts_used:      [
        { "category" => "skill",      "name" => "event planning" },
        { "category" => "skill",      "name" => "copywriting" },
        { "category" => "interest",   "name" => "local food systems" },
        { "category" => "connection", "name" => "local food co-op board" }
      ].to_json,
      time_commitment: "3 to 5 hrs/wk for 6 weeks before the event",
      impact_type:     "Direct service",
      first_step:      "Pick a target date and block it in your calendar, then send a one-line heads-up to the co-op board contact."
    }
  ].each do |attrs|
    inventory.project_ideas.create!(
      name:            attrs[:name],
      description:     attrs[:description],
      gifts_used:      attrs[:gifts_used],
      time_commitment: attrs[:time_commitment],
      impact_type:     attrs[:impact_type],
      first_step:      attrs[:first_step],
      gemini_raw:      SEED_RAW,
      position:        attrs[:position]
    )
  end

  puts "Seeded: 6 sample ProjectIdea records"
else
  puts "Skipped: ProjectIdea records already exist"
end
