require "test_helper"
require Rails.root.join("db/migrate/20261016120000_convert_money_to_cents")

class ConvertMoneyToCentsTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  VERSION = 20261016120000

  class FailsAfterConverting < ConvertMoneyToCents
    private

    def retype_as_integer
      super
      raise "forced failure in the last step"
    end
  end

  setup do
    migrate :down
    delete_test_rows
  end

  teardown do
    delete_test_rows
    migrate :up if decimal_column?("transactions", "amount")
  end

  test "up stores a transaction of 1,5 as 150 cents" do
    id = insert_transaction(amount: "1.5")

    migrate :up

    assert_equal 150, value("transactions", "amount", id)
  end

  test "up converts every money column" do
    ConvertMoneyToCents::COLUMNS.each do |table, column|
      connection.execute("UPDATE #{table} SET #{column} = 1.5 WHERE id = (SELECT MIN(id) FROM #{table})")
    end

    migrate :up

    ConvertMoneyToCents::COLUMNS.each do |table, column|
      id = connection.select_value("SELECT MIN(id) FROM #{table}")

      assert_equal "integer", connection.select_value("SELECT typeof(#{column}) FROM #{table} WHERE id = #{id}")
      assert_equal 150, value(table, column, id), "#{table}.#{column}"
      assert_equal :integer, connection.columns(table).find { |candidate| candidate.name == column }.type
    end
  end

  test "up converts edge values" do
    ids = {
      cent: insert_transaction(amount: "0.01"),
      large: insert_transaction(amount: "99999999.99"),
      negative: insert_transaction(amount: "1", balance: "-5.5"),
      none: insert_transaction(amount: "NULL"),
      noisy: insert_transaction(amount: "0.30000000000000004"),
      whole: insert_transaction(amount: "CAST(12 AS INTEGER)")
    }

    migrate :up

    assert_equal [ 1, 9_999_999_999, 100, nil, 30, 1200 ], ids.values_at(*%i[cent large negative none noisy whole])
      .map { |id| value("transactions", "amount", id) }
    assert_equal(-550, value("transactions", "original_balance_after_mutation", ids[:negative]))
    assert_equal "integer", connection.select_value("SELECT typeof(amount) FROM transactions WHERE id = #{ids[:noisy]}")
  end

  test "up aborts and changes nothing when a value has a fraction of a cent" do
    id = insert_transaction(amount: "0.005")

    error = assert_raises(StandardError) { migrate :up }

    assert_includes error.message, "transactions.amount id #{id}"
    assert decimal_column?("transactions", "amount")
    assert_in_delta(0.005, value("transactions", "amount", id))
  end

  test "up changes nothing when it fails after converting" do
    id = insert_transaction(amount: "1.5")

    assert_raises(StandardError) { migrate_with FailsAfterConverting, :up }

    assert decimal_column?("transactions", "amount")
    assert_in_delta(1.5, value("transactions", "amount", id))
    assert_empty connection.select_values("SELECT version FROM schema_migrations WHERE version = '#{VERSION}'")
  end

  test "foreign keys hold after up and after down" do
    insert_transaction(amount: "1.5")

    migrate :up

    assert_empty connection.select_rows("PRAGMA foreign_key_check")

    migrate :down

    assert_empty connection.select_rows("PRAGMA foreign_key_check")
  end

  test "receipt lines that add up to the total still do after up" do
    receipt_id = insert_receipt(total: "2.98")
    insert_receipt_line(receipt_id, full: "2.19", discount: "0.70", paid: "1.49")
    insert_receipt_line(receipt_id, full: "1.49", discount: "0", paid: "1.49")

    migrate :up

    assert_equal value("receipts", "total_amount", receipt_id),
                 connection.select_value("SELECT SUM(paid_amount) FROM receipt_lines WHERE receipt_id = #{receipt_id}")
    assert_equal 298, value("receipts", "total_amount", receipt_id)
  end

  test "down restores the original decimal values" do
    whole = insert_transaction(amount: "CAST(12 AS INTEGER)")
    fraction = insert_transaction(amount: "1.5", balance: "-158")
    cent = insert_transaction(amount: "0.07")

    migrate :up
    migrate :down

    assert_equal [ 12, 1.5, 0.07 ], [ whole, fraction, cent ].map { |id| value("transactions", "amount", id) }
    assert_equal "integer", connection.select_value("SELECT typeof(amount) FROM transactions WHERE id = #{whole}")
    assert_equal "real", connection.select_value("SELECT typeof(amount) FROM transactions WHERE id = #{fraction}")
    assert_equal(-158, value("transactions", "original_balance_after_mutation", fraction))
    assert decimal_column?("transactions", "amount")
  end

  private

  def connection
    ActiveRecord::Base.connection
  end

  def migrate(direction)
    ActiveRecord::Base.connection_pool.migration_context.run(direction, VERSION)
  rescue StandardError
    reset_schema_caches
    raise
  else
    reset_schema_caches
  end

  def migrate_with(migration_class, direction)
    pool = ActiveRecord::Base.connection_pool
    proxy = ActiveRecord::MigrationProxy.new("ConvertMoneyToCents", VERSION, nil, nil)
    proxy.instance_variable_set(:@migration, migration_class.new("ConvertMoneyToCents", VERSION))
    ActiveRecord::Migrator.new(direction, [ proxy ], pool.schema_migration, pool.internal_metadata, VERSION).migrate
  ensure
    reset_schema_caches
  end

  def reset_schema_caches
    ActiveRecord::Base.connection_pool.schema_cache.clear!
    ActiveRecord::Base.descendants.each(&:reset_column_information)
  end

  def delete_test_rows
    connection.execute(<<~SQL.squish)
      DELETE FROM receipt_lines
      WHERE receipt_id IN (SELECT id FROM receipts WHERE order_number = 'cents-test')
    SQL
    connection.execute("DELETE FROM receipts WHERE order_number = 'cents-test'")
    connection.execute("DELETE FROM transactions WHERE note = 'cents-test'")
  end

  def decimal_column?(table, column)
    connection.columns(table).find { |candidate| candidate.name == column }&.type == :decimal
  end

  def value(table, column, id)
    connection.select_value("SELECT #{column} FROM #{table} WHERE id = #{id}")
  end

  def insert_transaction(amount:, balance: "NULL")
    connection.execute(<<~SQL.squish)
      INSERT INTO transactions (type, amount, original_balance_after_mutation, note, created_at, updated_at)
      VALUES ('Debit', #{amount}, #{balance}, 'cents-test', datetime('now'), datetime('now'))
    SQL
    connection.select_value("SELECT last_insert_rowid()")
  end

  def insert_receipt(total:)
    connection.execute(<<~SQL.squish)
      INSERT INTO receipts (shop_id, issued_on, order_number, total_amount, created_at, updated_at)
      VALUES ((SELECT MIN(id) FROM accounts), date('now'), 'cents-test', #{total}, datetime('now'), datetime('now'))
    SQL
    connection.select_value("SELECT last_insert_rowid()")
  end

  def insert_receipt_line(receipt_id, full:, discount:, paid:)
    connection.execute(<<~SQL.squish)
      INSERT INTO receipt_lines (receipt_id, product_id, quantity, full_amount, discount_amount, paid_amount,
                                 created_at, updated_at)
      VALUES (#{receipt_id}, (SELECT MIN(id) FROM products), 1, #{full}, #{discount}, #{paid},
              datetime('now'), datetime('now'))
    SQL
  end
end
