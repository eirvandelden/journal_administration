require "test_helper"

class MergeableTest < ActiveSupport::TestCase
  setup do
    @target = accounts(:albert_heijn)
    @duplicate = accounts(:albert_heijn_duplicate)
  end

  class Refusals < MergeableTest
    test "merge refuses an empty selection" do
      assert_not @target.merge([])
      assert_not_empty @target.errors[:base]
    end

    test "merge refuses the target itself" do
      assert_not @target.merge([ @target ])
      assert_not_empty @target.errors[:base]
      assert Account.exists?(@target.id)
    end

    test "merge refuses a household duplicate" do
      assert_not @target.merge([ accounts(:savings) ])
      assert_not_empty @target.errors[:base]
      assert Account.exists?(accounts(:savings).id)
    end

    test "merge refuses a household target" do
      assert_not accounts(:checking).merge([ @duplicate ])
      assert_not_empty accounts(:checking).errors[:base]
      assert Account.exists?(@duplicate.id)
    end

    test "merge refuses a payment provider into a non-provider" do
      accounts(:adyen).update!(payment_provider: true)

      assert_not accounts(:jumbo).merge([ accounts(:adyen) ])
      assert_not_empty accounts(:jumbo).errors[:base]
    end

    test "merge accepts a payment provider into a payment provider" do
      accounts(:adyen).update!(payment_provider: true)
      accounts(:jumbo).update!(payment_provider: true)

      assert accounts(:jumbo).merge([ accounts(:adyen) ])
    end

    test "merge changes nothing when refused" do
      assert_no_changes -> { [ Account.count, AccountNumber.count, Receipt.where(shop: @duplicate).count ] } do
        @target.merge([ @duplicate, accounts(:savings) ])
      end

      assert_equal 2, Transaction.by_account(@duplicate.id).count
      assert_equal 2, @duplicate.reload.numbers.size
    end
  end

  class Merging < MergeableTest
    test "merge returns true" do
      assert @target.merge([ @duplicate ])
    end

    test "merge moves transactions on both sides" do
      @target.merge([ @duplicate ])

      assert_equal @target, transactions(:debit_from_ah_duplicate).reload.creditor
      assert_equal @target, transactions(:credit_from_ah_duplicate).reload.debitor
    end

    test "merge keeps the type of moved transactions" do
      @target.merge([ @duplicate ])

      assert_equal "Debit", transactions(:debit_from_ah_duplicate).reload.type
      assert_equal "Credit", transactions(:credit_from_ah_duplicate).reload.type
    end

    test "merge moves receipts" do
      @target.merge([ @duplicate ])

      assert_equal @target, receipts(:albert_heijn_duplicate_monday).reload.shop
    end

    test "merge moves aliases" do
      AccountAlias.create!(account: @duplicate, pattern: "AH online")

      @target.merge([ @duplicate ])

      assert_includes @target.account_aliases.reload.pluck(:pattern), "AH online"
    end

    test "merge moves numbers" do
      @target.merge([ @duplicate ])

      assert_equal %w[NL00ABNA9999999001 NL00ABNA9999999002 NL00ABNA9999999999], @target.reload.numbers.sort
    end

    test "merge destroys the duplicates" do
      assert_difference "Account.count", -1 do
        @target.merge([ @duplicate ])
      end

      assert_not Account.exists?(@duplicate.id)
    end

    test "merge keeps the target's name and category" do
      @duplicate.update!(category: categories(:rent))

      @target.merge([ @duplicate ])

      assert_equal "Albert Heijn B.V.", @target.reload.name
      assert_equal categories(:supermarket), @target.category
    end

    test "merge gives a target without category the first duplicate's category" do
      target = accounts(:jumbo)
      without_category = Account.create!(name: "Jumbo zonder categorie")
      first = Account.create!(name: "Jumbo eerste", category: categories(:bakery))
      second = Account.create!(name: "Jumbo tweede", category: categories(:rent))

      target.merge([ second, first, without_category ])

      assert_equal categories(:bakery), target.reload.category
    end

    test "merge leaves a target without category when no duplicate has one" do
      accounts(:jumbo).merge([ accounts(:aon) ])

      assert_nil accounts(:jumbo).reload.category
    end

    test "merge merges several duplicates at once" do
      other = Account.create!(
        name: "AH Amsterdam",
        account_numbers: [ AccountNumber.new(number: "NL00ABNA9999999003") ]
      )

      assert_difference "Account.count", -2 do
        @target.merge([ @duplicate, other ])
      end

      assert_includes @target.reload.numbers, "NL00ABNA9999999003"
    end

    test "the merged account's transactions add up" do
      before = Transaction.by_account(@target.id).count + Transaction.by_account(@duplicate.id).count

      @target.merge([ @duplicate ])

      assert_equal before, Transaction.by_account(@target.id).count
    end
  end

  class Counting < MergeableTest
    test "transactions_count_by_account counts the transactions on either side per account" do
      assert_equal({ @duplicate.id => 2 }, Account.transactions_count_by_account([ @duplicate.id ]))
    end

    test "transactions_count_by_account counts a transaction between two accounts once for each" do
      other = Account.create!(name: "AH Other")
      Debit.create!(
        amount: 100, booked_at: Time.current, interest_at: Time.current,
        debitor: accounts(:checking), creditor: @duplicate, category: categories(:gifts)
      ).update_columns(debitor_account_id: other.id)

      counts = Account.transactions_count_by_account([ @duplicate.id, other.id ])

      assert_equal [ 3, 1 ], counts.values_at(@duplicate.id, other.id)
    end

    test "transactions_count_by_account is empty for no accounts" do
      assert_empty Account.transactions_count_by_account([])
    end

    test "receipts_count_by_account counts the receipts bought at each account" do
      assert_equal({ @duplicate.id => 1 }, Account.receipts_count_by_account([ @duplicate.id, accounts(:jumbo).id ]))
    end
  end
end
