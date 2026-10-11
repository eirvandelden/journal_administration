# Lets an external account stand for a payment provider that collects for many merchants
#
# Providers such as Adyen, Mollie or Buckaroo receive payments for many shops on one IBAN, so
# the IBAN alone cannot say where money was spent. For an account marked as a payment provider,
# the merchant named in the transaction description decides the counterparty instead.
module PaymentProvider
  extend ActiveSupport::Concern

  # Labels ING writes after the merchant name in a description.
  NEXT_LABELS = [ "Omschrijving", "IBAN", "Kenmerk", "Machtiging ID", "Datum/Tijd", "Valutadatum" ].freeze
  MERCHANT = /(?:\A|\s)Naam: (.*?)(?=\s(?:#{NEXT_LABELS.map { |label| Regexp.escape(label) }.join("|")}):|\z)/m
  PROVIDER_SUFFIX = /(?:\A|\s)(?:via|by)\s.*\z/i

  # Raised when one transaction cannot move; names that transaction so it can be found and fixed
  class MoveFailed < StandardError
    attr_reader :payment

    def initialize(payment, reason)
      @payment = payment
      super("#{payment.model_name.human} ##{payment.id}: #{reason}")
    end
  end

  included do
    validate :payment_provider_must_be_external
  end

  # Finds the account a payment through this account really belongs to
  #
  # Reads the merchant from the description, then resolves it through existing aliases, then
  # external account names, and finally creates an account for it. Stays on this account when
  # it is no provider, or when the description names no usable merchant.
  #
  # @param description [String, nil] The ING description of the payment
  # @return [Account] The merchant's account, or this account
  def counterparty_for(description)
    return self unless payment_provider?

    merchant = merchant_name(description)
    return self if merchant.blank? || own_name?(merchant)

    merchant_account(merchant)
  end

  # Moves this provider's transactions to the merchants named in them
  #
  # Everything moves or nothing does. A transaction that stays on the provider is neither
  # saved nor counted, so a second run moves nothing.
  #
  # @return [Integer] Number of transactions moved
  # @raise [MoveFailed] If one transaction cannot move; nothing has moved then
  def move_transactions_to_merchants
    return 0 unless payment_provider?

    transaction { Transaction.by_account(id).includes(:debitor, :creditor).sum { |payment| move(payment) } }
  end

  private

  def payment_provider_must_be_external
    return unless payment_provider? && !external?

    errors.add(:payment_provider, :must_be_external)
  end

  def move(payment)
    merchant = counterparty_for(payment.original_note)
    return 0 if merchant == self

    payment.move_counterparty(from: self, to: merchant)
    1
  rescue ActiveRecord::RecordInvalid => error
    raise MoveFailed.new(payment, error.message)
  end

  def merchant_name(description)
    description.to_s[MERCHANT, 1]&.sub(PROVIDER_SUFFIX, "")&.strip
  end

  def own_name?(merchant)
    names = [ name, *account_aliases.pluck(:pattern) ]

    names.compact.any? { |own| own.strip.casecmp?(merchant) }
  end

  def merchant_account(merchant)
    Account.external.find_by_alias(merchant) ||
      Account.external.where("LOWER(name) = LOWER(?)", merchant).order(:id).first ||
      Account.create!(name: merchant)
  end
end
