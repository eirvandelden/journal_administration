class Category < ApplicationRecord
  DIRECTIONS = %i[debit credit].freeze
  enum direction: DIRECTIONS

  has_many :transactions
  has_many :secondaries, class_name: 'Category',
                         foreign_key: 'parent_category_id'

  belongs_to :parent_category, class_name: 'Category', optional: true

  default_scope { order(name: :asc) }
  scope :groups, -> { where(parent_category_id: nil) }

  validates :direction, presence: true

  # Instance methods
  def children
    Category.where(parent_category_id: id).or(Category.where(id: id))
  end

  def to_s
    if parent_category.present?
      "#{parent_category.name} - #{name}"
    else
      name
    end
  end
end
