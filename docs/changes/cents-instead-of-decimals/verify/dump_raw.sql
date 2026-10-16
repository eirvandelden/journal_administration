.mode list
.separator ", "
SELECT 'appropriations', 'amount', id, typeof(amount), CAST(amount AS TEXT) FROM appropriations WHERE amount IS NOT NULL
UNION ALL SELECT 'budget_categories', 'amount', id, typeof(amount), CAST(amount AS TEXT) FROM budget_categories WHERE amount IS NOT NULL
UNION ALL SELECT 'chattels', 'purchase_price', id, typeof(purchase_price), CAST(purchase_price AS TEXT) FROM chattels WHERE purchase_price IS NOT NULL
UNION ALL SELECT 'receipt_lines', 'full_amount', id, typeof(full_amount), CAST(full_amount AS TEXT) FROM receipt_lines WHERE full_amount IS NOT NULL
UNION ALL SELECT 'receipt_lines', 'discount_amount', id, typeof(discount_amount), CAST(discount_amount AS TEXT) FROM receipt_lines WHERE discount_amount IS NOT NULL
UNION ALL SELECT 'receipt_lines', 'paid_amount', id, typeof(paid_amount), CAST(paid_amount AS TEXT) FROM receipt_lines WHERE paid_amount IS NOT NULL
UNION ALL SELECT 'receipts', 'total_amount', id, typeof(total_amount), CAST(total_amount AS TEXT) FROM receipts WHERE total_amount IS NOT NULL
UNION ALL SELECT 'transaction_splits', 'amount', id, typeof(amount), CAST(amount AS TEXT) FROM transaction_splits WHERE amount IS NOT NULL
UNION ALL SELECT 'transactions', 'amount', id, typeof(amount), CAST(amount AS TEXT) FROM transactions WHERE amount IS NOT NULL
UNION ALL SELECT 'transactions', 'original_balance_after_mutation', id, typeof(original_balance_after_mutation), CAST(original_balance_after_mutation AS TEXT) FROM transactions WHERE original_balance_after_mutation IS NOT NULL
ORDER BY 1, 2, 3;
