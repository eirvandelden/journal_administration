# Stores every money amount as whole cents in an integer column.
#
# Works with SQL and the connection only, never a model. It aborts before any
# write when a value has a fraction of a cent. Rails runs a SQLite migration in
# one transaction, so a failure at any later step leaves the data as it was.
class ConvertMoneyToCents < ActiveRecord::Migration[8.1]
  COLUMNS = [
    %w[appropriations amount],
    %w[budget_categories amount],
    %w[chattels purchase_price],
    %w[receipt_lines full_amount],
    %w[receipt_lines discount_amount],
    %w[receipt_lines paid_amount],
    %w[receipts total_amount],
    %w[transaction_splits amount],
    %w[transactions amount],
    %w[transactions original_balance_after_mutation]
  ].freeze
  NOISE = BigDecimal("0.000001")

  def up
    refuse_fractions_of_a_cent
    convert_to_cents
    retype_as_integer
  end

  def down
    retype_as_decimal
    convert_to_euros
  end

  private

  def refuse_fractions_of_a_cent
    fractions = COLUMNS.flat_map { |table, column| fractions_in(table, column) }
    return if fractions.empty?

    raise "Cannot convert to cents, a value has a fraction of a cent: #{fractions.join(', ')}"
  end

  def fractions_in(table, column)
    select_rows("SELECT id, CAST(#{column} AS TEXT) FROM #{table} WHERE #{column} IS NOT NULL").filter_map do |id, text|
      "#{table}.#{column} id #{id} (#{text})" unless whole_cents?(BigDecimal(text) * 100)
    end
  end

  # SQLite prints a REAL with up to 17 digits, so float noise such as
  # 0.30000000000000004 shows. Anything within a millionth of a cent counts as whole.
  def whole_cents?(cents)
    fraction = cents.frac.abs
    fraction < NOISE || fraction > 1 - NOISE
  end

  def convert_to_cents
    COLUMNS.each do |table, column|
      execute "UPDATE #{table} SET #{column} = CAST(ROUND(#{column} * 100) AS INTEGER) WHERE #{column} IS NOT NULL"
    end
  end

  def retype_as_integer
    COLUMNS.each do |table, column|
      change_column table, column, :integer, **integer_options(table, column)
    end
  end

  def integer_options(table, column)
    options = { null: nullable?(table, column) }
    options[:default] = 0 if column == "discount_amount"
    options
  end

  def nullable?(table, column)
    columns(table).find { |candidate| candidate.name == column }.null
  end

  def retype_as_decimal
    COLUMNS.each do |table, column|
      change_column table, column, :decimal, **decimal_options(table, column)
    end
  end

  def decimal_options(table, column)
    options = { null: nullable?(table, column) }
    unless column == "original_balance_after_mutation"
      options[:precision] = 10
      options[:scale] = 2
    end
    options[:default] = "0.0" if column == "discount_amount"
    options
  end

  def convert_to_euros
    COLUMNS.each do |table, column|
      execute <<~SQL.squish
        UPDATE #{table}
        SET #{column} = CASE WHEN #{column} % 100 = 0 THEN #{column} / 100 ELSE #{column} / 100.0 END
        WHERE #{column} IS NOT NULL
      SQL
    end
  end
end
