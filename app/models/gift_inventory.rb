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
    # Normalize on write: accept Array, JSON string, or newline-separated string
    define_method(:"#{field}=") do |val|
      normalized = case val
                   when Array   then val.to_json
                   when /\A\[/  then val
                   else val.to_s.split(/\n+/).map(&:strip).reject(&:blank?).to_json
                   end
      super(normalized)
    end

    define_method(:"#{field}_list") { JSON.parse(send(field)) rescue [] }
    define_method(:"#{field}_list=") { |val| send(:"#{field}=", val) }
  end

  private

  def skills_count
    errors.add(:skills, "must have between 5 and 8 entries") unless skills_list.length.between?(5, 8)
  end

  def interests_count
    errors.add(:interests, "must have between 3 and 5 entries") unless interests_list.length.between?(3, 5)
  end

  def connections_count
    errors.add(:connections, "must have between 3 and 5 entries") unless connections_list.length.between?(3, 5)
  end

  def experience_areas_count
    errors.add(:experience_areas, "must have at least 1 entry") if experience_areas_list.empty?
  end
end
