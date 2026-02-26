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
    row = [ "20240115", "Albert Heijn", "NL54INGB0671255150", "NL00BANK9999999999",
            "GT", "Af", "25,50", "Card payment", "Groceries at AH", "1000,00", "" ]

    assert_difference "Transaction.count", 1 do
      Importing::ING::ImportJob.perform_now(row)
    end
  end

  test "creates their_account when it does not exist" do
    row = [ "20240115", "New Store", accounts(:checking).account_number, "NL00NEW2222222222",
            "GT", "Af", "10,00", "Card payment", "Shopping", "1000,00", "" ]

    assert_difference "Account.count", 1 do
      Importing::ING::ImportJob.perform_now(row)
    end
  end

  test "resolves existing accounts by account number" do
    row = [ "20240115", "Some Name", accounts(:checking).account_number,
            accounts(:albert_heijn).account_number,
            "GT", "Af", "15,00", "Card payment", "Shopping", "1000,00", "" ]

    assert_no_difference "Account.count" do
      Importing::ING::ImportJob.perform_now(row)
    end
  end

  test "skips duplicate family transfer rows without raising" do
    row = [ "20240115", "Savings transfer", accounts(:checking).account_number, accounts(:savings).account_number,
            "OV", "Af", "500,00", "Wire transfer", "Transfer", "1000,00", "" ]

    assert_difference "Transaction.count", 1 do
      Importing::ING::ImportJob.perform_now(row)
    end

    assert_no_difference "Transaction.count" do
      Importing::ING::ImportJob.perform_now(row)
    end
  end

  test "ignores rows with an invalid date" do
    row = [ "not-a-date", "Albert Heijn", accounts(:checking).account_number, "NL00BANK9999999999",
            "GT", "Af", "25,50", "Card payment", "Groceries at AH", "1000,00", "" ]

    assert_no_difference "Transaction.count" do
      Importing::ING::ImportJob.perform_now(row)
    end
  end
end
