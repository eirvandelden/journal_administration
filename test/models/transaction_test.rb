require 'test_helper'

class TransactionTest < ActiveSupport::TestCase

  # TODO: argument is an array of strings, not a string
  test 'A header string raises an error' do
    assert_raises Transaction::HeaderStringError do
      nil_transaction = Transaction.new '"Datum","Naam / Omschrijving","Rekening","Tegenrekening","Code","Af Bij","Bedrag (EUR)","MutatieSoort","Mededelingen"'
    end
  end

  # TODO: van ons + naar ander + AF = credit
  # TODO: van ons = naar ander + ander heeft een credit-category + af = transaction heeft dezesfde category
  # TODO: van ons + naar ander + BIJ = debit
  # TODO: van ons + naar ander + ander heeft een debit-category + bij = transaction heeft dezefde category
  # TODO: van ons + naar ons = transfer
  # TODO: van ons + naar ons = category "Transfer"
  # TODO: beschrijving is nummer = onze rekening (potje)
  # TODO: rekening is onbekend maakt een nieuw account
  # TODO: tegenrekening is onbekend maakt een nieuw account

  # test 'It parsess values from a csv record' do
  #   parsed_transaction = Transaction.new '"20200229", "Etienne", "rekening", "tegenrekening", "GT", "Bij", "12,95", "Online bankieren", "Mededeling"'

  #   assert_equal Date.new(2020, 02, 29), parsed_transaction.booked_at
  # end
end
