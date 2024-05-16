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
      ])
    end

    assert_equal Transaction.count, 1
  end
end
