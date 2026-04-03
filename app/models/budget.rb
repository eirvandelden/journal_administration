# A time-bounded household budget with per-category allocations.
#
# Only one budget may be active at a time, enforced via the chain invariant:
# creating or updating a budget automatically closes the predecessor.
class Budget < ApplicationRecord
  belongs_to :closed_by_budget, class_name: "Budget", optional: true

  has_many :budget_categories, dependent: :destroy
  has_many :categories, through: :budget_categories

  accepts_nested_attributes_for :budget_categories, allow_destroy: true, reject_if: :all_blank

  validates :starts_at, presence: true
  validates :starts_at, uniqueness: true
  validates :ends_at, comparison: { greater_than: :starts_at }, allow_nil: true
  validate :starts_at_not_before_predecessor
  validate :ends_at_not_past_successor

  before_validation :normalize_dates
  after_create  :close_open_predecessor
  after_update  :reconcile_predecessors, if: :saved_change_to_starts_at?

  scope :active, -> {
    where("starts_at <= ?", Time.current)
      .where("ends_at IS NULL OR ends_at > ?", Time.current)
  }
  scope :future, -> { where("starts_at > ?", Time.current) }
  scope :past,   -> { where("ends_at IS NOT NULL AND ends_at <= ?", Time.current) }
  scope :chronological, -> { order(starts_at: :asc) }

  # @return [Boolean]
  def active? = starts_at <= Time.current && (ends_at.nil? || ends_at > Time.current)

  # @return [Boolean]
  def future? = starts_at > Time.current

  # @return [Boolean]
  def past? = ends_at.present? && ends_at <= Time.current

  # Returns suggested budget amounts per parent category based on 36-month historical averages.
  #
  # Scales to the budget's period length (defaults to 30 days for open-ended budgets).
  #
  # @return [Hash{Category => BigDecimal}]
  def suggested_amounts
    lookback = suggestion_lookback_range
    period_days = suggestion_period_days

    [ Debit, Credit ].each_with_object({}) do |klass, result|
      suggestion_totals_by_parent(klass, lookback).each do |parent, total|
        daily_avg = total.to_f / suggestion_lookback_days(lookback)
        result[parent] = ((result[parent] || 0) + daily_avg * period_days).round(2)
      end
    end
  end

  # Applies suggested amounts to budget_categories in memory (does not save).
  #
  # Builds or updates in-memory budget_categories based on suggested_amounts.
  # Call save to persist.
  #
  # @return [void]
  def apply_suggestions
    suggested_amounts.each do |category, amount|
      existing = budget_categories.find { |bc| bc.category_id == category.id }
      if existing
        existing.amount = amount
      else
        budget_categories.build(category: category, amount: amount)
      end
    end
  end

  private

  def suggestion_period_days
    ends_at ? ((ends_at.to_date - starts_at.to_date).to_i + 1) : 30
  end

  def suggestion_lookback_range
    lookback_end   = Time.current.end_of_day
    lookback_start = (lookback_end - 36.months).beginning_of_day
    lookback_start..lookback_end
  end

  def suggestion_lookback_days(range)
    ((range.end.to_date - range.begin.to_date).to_i + 1).to_f
  end

  def suggestion_totals_by_parent(klass, lookback)
    transfer_cat_id = Category.find_by(name: "Transfer")&.id
    scope  = klass.where(booked_at: lookback)

    unsplit = scope.where.missing(:transaction_splits)
                   .group(:category_id).sum(:amount)
                   .except(transfer_cat_id)
    split   = scope.joins(:transaction_splits)
                   .group("transaction_splits.category_id")
                   .sum("transaction_splits.amount")
                   .except(transfer_cat_id)

    totals = unsplit.merge(split) { |_k, a, b| a + b }
    cat_ids = totals.keys.compact
    categories = Category.where(id: cat_ids).includes(:parent_category).index_by(&:id)

    totals.each_with_object({}) do |(cat_id, total), result|
      category = categories[cat_id]
      next unless category
      parent = category.parent_category || category
      result[parent] = (result[parent] || 0) + total
    end
  end

  def normalize_dates
    self.starts_at = starts_at.beginning_of_day if starts_at.present?
    self.ends_at   = ends_at.end_of_day          if ends_at.present?
  end

  def predecessor
    Budget.where("starts_at < ?", starts_at).order(starts_at: :desc).first
  end

  def successor
    scope = Budget.where("starts_at > ?", starts_at)
    scope = scope.where.not(id: id) if persisted?
    scope.order(starts_at: :asc).first
  end

  def close_open_predecessor
    pred = predecessor
    return unless pred
    return unless pred.ends_at.nil? || pred.ends_at >= starts_at

    pred.update_columns(ends_at: derived_predecessor_ends_at, closed_by_budget_id: id)
  end

  def reconcile_predecessors
    restore_former_predecessor
    reclose_current_predecessor
  end

  def restore_former_predecessor
    pred = predecessor_before_last_save
    return unless pred
    return unless pred.closed_by_budget_id == id

    successor = successor_for(pred)
    ends_at = successor ? derived_predecessor_ends_at_for(successor.starts_at) : nil
    pred.update_columns(ends_at: ends_at, closed_by_budget_id: successor&.id)
  end

  def reclose_current_predecessor
    pred = predecessor
    return unless pred
    return unless pred.ends_at.nil? || pred.ends_at >= starts_at

    pred.update_columns(ends_at: derived_predecessor_ends_at, closed_by_budget_id: id)
  end

  def derived_predecessor_ends_at
    derived_predecessor_ends_at_for(starts_at)
  end

  def derived_predecessor_ends_at_for(time)
    (time.beginning_of_day - 1.day).end_of_day
  end

  def predecessor_before_last_save
    return unless starts_at_before_last_save

    Budget.where.not(id: id)
      .where("starts_at < ?", starts_at_before_last_save)
      .order(starts_at: :desc)
      .first
  end

  def successor_for(budget)
    Budget.where("starts_at > ?", budget.starts_at)
      .where.not(id: budget.id)
      .order(starts_at: :asc)
      .first
  end

  def starts_at_not_before_predecessor
    return unless starts_at.present?

    pred = predecessor
    return unless pred

    errors.add(:starts_at, :before_predecessor) if starts_at < pred.starts_at
  end

  def ends_at_not_past_successor
    succ = successor
    return unless succ

    if ends_at.nil?
      errors.add(:ends_at, :open_ended_with_successor)
    elsif ends_at >= succ.starts_at
      errors.add(:ends_at, :overlaps_successor)
    end
  end
end
