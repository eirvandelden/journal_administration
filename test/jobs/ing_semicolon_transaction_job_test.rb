require "test_helper"

class IngSemicolonTransactionJobTest < ActiveJob::TestCase
  test "on a header row" do
    perform_enqueued_jobs do
      IngSemicolonTransactionJob.perform_later(["Datum", "Naam / Omschrijving", "Rekening", "Tegenrekening", "Code",
"Af Bij""Bedrag (EUR)", "Mutatiesoort", "Mededelingen", "Saldo na mutatie", "Tag"])
    end

    assert_equal Transaction.count, 0
  end

  test "with a valid row, for an unknown account" do
    perform_enqueued_jobs do
      IngSemicolonTransactionJob.perform_later([
        "20200818", "EIR van Delden-de la Haije, M van Delden-de la Haije", "NL54INGB0671255150", "", "GT", "Bij",
        "100,00", "Online bankieren", "Van Oranje spaarrekening L29925215 Valutadatum: 18-08-2020", "158,24", "☀️"
      ])
    end

    assert_equal Transaction.count, 1
  end

  test "with a valid row, if initiator_account_name is a variant, match to an existing account" do
    ah = Account.find_or_create_by(name: "Albert Heijn B.V.")

    [
      "ALBERT HEIJN 2921 EINDHOVEN NLD",
      "Albert Heijn 5610 'S-HERTOGENBO",
      "Albert Heijn 123456 Zaandam",
      "AH Strijp EINDHOVEN NLD",
      "AH to go Sittard 5823 SITTARD",
      "1315641 ALBERT HEIJN 1408> UTREC",
    ].each do |current_name|
      perform_enqueued_jobs do
        IngSemicolonTransactionJob.perform_later([
          "20240229", current_name, "NL00INGB0123456789", "", "", "Af", "75,00", "Online bankieren", "beschrijving", "75,00", "🛒"
        ])
      end

      assert_equal Transaction.last.debitor_account_id, ah.id
    end

    jumbo = Account.find_or_create_by(name: "Jumbo B.V.")
    [
      "Jumbo Foodmarkt Veghel VEGHEL",
      "Jumbo Supermarkten BV Veghel NLD",
      "Jumbo R Verhagen EINDHOVEN NLD"
    ].each do |current_name|
      perform_enqueued_jobs do
        IngSemicolonTransactionJob.perform_later([
          "20240229", current_name, "NL00INGB0123456789", "", "", "Af", "75,00", "Online bankieren", "beschrijving", "75,00", "🛒"
        ])
      end

      assert_equal Transaction.last.debitor_account_id, jumbo.id
    end

    kruidvat = Account.find_or_create_by(name: "Kruidvat B.V.")
    [
      "Kruidvat 6939 BREUKELEN UT NLD",
      "Kruidvat 7661 EINDHOVEN NLD",
      "1840003 KRUIDVAT 3140> UTRECHT"
    ].each do |current_name|
      perform_enqueued_jobs do
        IngSemicolonTransactionJob.perform_later([
          "20240229", current_name, "NL00INGB0123456789", "", "", "Af", "75,00", "Online bankieren", "beschrijving", "75,00", "🛒"
        ])
      end

      assert_equal Transaction.last.debitor_account_id, kruidvat.id
    end
  end
end
