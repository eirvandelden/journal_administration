require "test_helper"

class ConvertMoneyToCentsTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  VERSION = 20261016120000

  setup do
    migrate :down
    connection.execute("DELETE FROM transactions WHERE note = 'cents-test'")
  end

  teardown do
    connection.execute("DELETE FROM transactions WHERE note = 'cents-test'")
    migrate :up if decimal_column?("transactions", "amount")
  end

  test "up stores a transaction of 1,5 as 150 cents" do
    id = insert_transaction(amount: "1.5")

    migrate :up

    assert_equal 150, connection.select_value("SELECT amount FROM transactions WHERE id = #{id}")
  end

  private

  def connection
    ActiveRecord::Base.connection
  end

  def migrate(direction)
    context = ActiveRecord::Base.connection_pool.migration_context
    context.public_send(direction, VERSION)
    ActiveRecord::Base.connection_pool.schema_cache.clear!
    ActiveRecord::Base.descendants.each(&:reset_column_information)
  end

  def decimal_column?(table, column)
    connection.columns(table).find { |candidate| candidate.name == column }&.type == :decimal
  end

  def insert_transaction(amount:, balance: "NULL")
    connection.execute(<<~SQL.squish)
      INSERT INTO transactions (type, amount, original_balance_after_mutation, note, created_at, updated_at)
      VALUES ('Debit', #{amount}, #{balance}, 'cents-test', datetime('now'), datetime('now'))
    SQL
    connection.select_value("SELECT last_insert_rowid()")
  end
end
