require "test_helper"

class Importing::ING::ImportJobTest < ActiveJob::TestCase
  test "skips header rows" do
    header = [ "Datum", "Naam / Omschrijving", "Rekening", "Tegenrekening",
              "Code", "Af Bij", "Bedrag (EUR)", "Mutatiesoort", "Mededelingen",
              "Saldo na mutatie", "Tag" ]

    assert_no_difference "Transaction.count" do
      Importing::ING::ImportJob.perform_now(header)
    end
  end

  test "creates a transaction from a valid CSV row" do
    row = [ "20240115", "Albert Heijn", "NL54INGB0671255150", "NL00ABNA9999999999",
           "GT", "Af", "25,50", "Betaalautomaat", "Groceries at AH", "1000,00", "" ]

    assert_difference "Transaction.count", 1 do
      Importing::ING::ImportJob.perform_now(row)
    end
  end

  test "creates their_account when it does not exist" do
    row = [ "20240115", "New Store", account_numbers(:checking).number, "NL00NEW2222222222",
           "GT", "Af", "10,00", "Betaalautomaat", "Shopping", "1000,00", "" ]

    assert_difference "Account.count", 1 do
      Importing::ING::ImportJob.perform_now(row)
    end
  end

  test "resolves existing accounts by account number" do
    row = [ "20240115", "Some Name", account_numbers(:checking).number,
           account_numbers(:albert_heijn).number,
           "GT", "Af", "15,00", "Betaalautomaat", "Shopping", "1000,00", "" ]

    assert_no_difference "Account.count" do
      Importing::ING::ImportJob.perform_now(row)
    end
  end

  test "importing from a known second number creates no account" do
    row = import_row(account_numbers(:albert_heijn_duplicate_second).number)

    assert_no_difference "Account.count" do
      Importing::ING::ImportJob.perform_now(row)
    end
  end

  test "a transaction from any number of an account books on that account" do
    account_numbers = account_numbers(:albert_heijn_duplicate_first, :albert_heijn_duplicate_second)

    account_numbers.each { |number| Importing::ING::ImportJob.perform_now(import_row(number.number)) }

    assert_equal [ accounts(:albert_heijn_duplicate) ] * 2, Transaction.reorder(:id).last(2).map(&:creditor)
  end

  test "a transaction from a number typed with spaces books on the owner of that number" do
    Importing::ING::ImportJob.perform_now(import_row("nl00 abna 9999 999999"))

    assert_equal accounts(:albert_heijn), last_transaction.creditor
  end

  test "a payment through a shared provider books on the merchant's existing account" do
    accounts(:adyen).update!(payment_provider: true)

    Importing::ING::ImportJob.perform_now(provider_row("Kruidvat"))

    assert_equal accounts(:kruidvat), last_transaction.debitor
  end

  test "a payment through a shared provider to an unknown merchant creates that merchant" do
    accounts(:adyen).update!(payment_provider: true)

    assert_difference "Account.count", 1 do
      Importing::ING::ImportJob.perform_now(provider_row("Kirovanni/Foodticket"))
    end

    assert_equal "Kirovanni/Foodticket", last_transaction.debitor.name
  end

  test "a via suffix is dropped from the merchant name" do
    mollie = Account.create!(
      name: "Stichting Mollie Payments",
      account_numbers: [ AccountNumber.new(number: "NL00MOLL0000000001") ],
      payment_provider: true
    )

    Importing::ING::ImportJob.perform_now(
      provider_row("Partydeco", number: mollie.numbers.first, suffix: " via Stichting Mollie Payments")
    )

    assert_equal "Partydeco", last_transaction.debitor.name
  end

  test "a by suffix is dropped from the merchant name" do
    buckaroo = Account.create!(
      name: "STICHTING DERDENGELDEN BUCKAROO",
      account_numbers: [ AccountNumber.new(number: "NL00BUCK0000000001") ],
      payment_provider: true
    )

    Importing::ING::ImportJob.perform_now(
      provider_row("Topbloemen", number: buckaroo.numbers.first, suffix: " by Buckaroo")
    )

    assert_equal "Topbloemen", last_transaction.debitor.name
  end

  test "a payment naming the provider itself stays on the provider" do
    accounts(:adyen).update!(payment_provider: true)

    Importing::ING::ImportJob.perform_now(provider_row("Adyen"))

    assert_equal accounts(:adyen), last_transaction.debitor
  end

  test "a refund through a shared provider books on the merchant" do
    accounts(:adyen).update!(payment_provider: true)

    Importing::ING::ImportJob.perform_now(provider_row("Kruidvat", direction: "Bij"))

    assert_equal [ "Debit", accounts(:kruidvat) ], [ last_transaction.type, last_transaction.creditor ]
  end

  test "a payment to an account that is not a shared provider books on that account" do
    Importing::ING::ImportJob.perform_now(provider_row("Kruidvat", number: account_numbers(:aon).number))

    assert_equal accounts(:aon), last_transaction.debitor
  end

  test "an unmarked provider books new payments on itself" do
    Importing::ING::ImportJob.perform_now(provider_row("Kruidvat"))

    assert_equal accounts(:adyen), last_transaction.debitor
  end

  private

  def import_row(number)
    [ "20240115", "Albert Heijn", account_numbers(:checking).number, number,
      "GT", "Bij", "15,00", "Betaalautomaat", "Refund", "1000,00", "" ]
  end

  def last_transaction = Transaction.reorder(:id).last

  def provider_row(merchant, number: account_numbers(:adyen).number, direction: "Af", suffix: "")
    description = "Naam: #{merchant}#{suffix} Omschrijving: Payment IBAN: #{number} Kenmerk: 99"

    [ "20260815", merchant, account_numbers(:checking).number, number,
      "GT", direction, "10,00", "Betaalautomaat", description, "1000,00", "" ]
  end
end
