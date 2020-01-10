require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  test 'A header string raises an error' do
    assert_raises Transaction::HeaderStringError do
      nil_transaction = Transaction.new '"Datum","Naam / Omschrijving","Rekening","Tegenrekening","Code","Af Bij","Bedrag (EUR)","MutatieSoort","Mededelingen"'
    end
  end

  # test 'It parsess values from a csv record' do
  #   parsed_transaction = Transaction.new '"20200229", "Etienne", "rekening", "tegenrekening", "GT", "Bij", "12,95", "Online bankieren", "Mededeling"'

  #   assert_equal Date.new(2020, 02, 29), parsed_transaction.booked_at
  # end
  
  # describe 'when given a header rule' do
  #   test 'it returns a nil object'
  # end

  # describe 'with a debit transaction from others to us' do
  # end

  # describe 'with a credit transaction from us to others' do
  # end

  # describe 'with a transfer transaction from us, to us' do
  # end

  # describe 'with a valid transaction' do
  #   describe 'with their account missing'
  #   describe 'with our account missing'
  # end

end
