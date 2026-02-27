require "test_helper"

class IngSemicolonTransactionJobTest < ActiveJob::TestCase
  test "on a header row" do
    assert_no_difference "Transaction.count" do
      perform_enqueued_jobs do
        IngSemicolonTransactionJob.perform_later([
          "Datum",
          "Naam / Omschrijving",
          "Rekening",
          "Tegenrekening",
          "Code",
          "Af Bij", "Bedrag (EUR)",
          "Mutatiesoort",
          "Mededelingen",
          "Saldo na mutatie",
          "Tag"
        ])
      end
    end
  end

  test "with a valid row, for an unknown account" do
    assert_difference "Transaction.count", 1 do
      perform_enqueued_jobs do
        IngSemicolonTransactionJob.perform_later([
          "20200818", "EIR van Delden-de la Haije, M van Delden-de la Haije", "NL54INGB0671255150", "", "GT", "Bij",
          "100,00", "Online bankieren", "Van Oranje spaarrekening L29925215 Valutadatum: 18-08-2020", "158,24", "\u2600\uFE0F"
        ])
      end
    end
  end

  test "with a valid row, if initiator_account_name is a variant, match to an existing account" do
    assert_variant_names_match_account("Albert Heijn B.V.", albert_heijn_names)
    assert_variant_names_match_account("Jumbo B.V.", jumbo_names)
    assert_variant_names_match_account("Kruidvat B.V.", kruidvat_names)
  end

  private

  def assert_variant_names_match_account(account_name, names)
    expected_account = Account.find_or_create_by(name: account_name)
    names.each { |current_name| assert_variant_name_matches_account(current_name, expected_account.id) }
  end

  def assert_variant_name_matches_account(current_name, expected_account_id)
    perform_enqueued_jobs do
      IngSemicolonTransactionJob.perform_later([
        "20240229", current_name, "NL00INGB0123456789", "", "", "Af",
        "75,00", "Online bankieren", "beschrijving", "75,00", "\u{1F6D2}" ])
    end
    txn = Transaction.unscoped.last
    their_mutation = txn.mutations.find { |m| m.amount > 0 }
    assert_equal expected_account_id, their_mutation.account_id
  end

  def albert_heijn_names
    [
      "ALBERT HEIJN 2921 EINDHOVEN NLD",
      "Albert Heijn 5610 'S-HERTOGENBO",
      "Albert Heijn 123456 Zaandam",
      "AH Strijp EINDHOVEN NLD",
      "AH to go Sittard 5823 SITTARD",
      "1315641 ALBERT HEIJN 1408> UTREC"
    ]
  end

  def jumbo_names
    [
      "Jumbo Foodmarkt Veghel VEGHEL",
      "Jumbo Supermarkten BV Veghel NLD",
      "Jumbo R Verhagen EINDHOVEN NLD"
    ]
  end

  def kruidvat_names
    [
      "Kruidvat 6939 BREUKELEN UT NLD",
      "Kruidvat 7661 EINDHOVEN NLD",
      "1840003 KRUIDVAT 3140> UTRECHT"
    ]
  end
end
