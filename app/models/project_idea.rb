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
