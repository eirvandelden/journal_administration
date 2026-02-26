# JournalAdministration

Fill in the journal with all your transactions. Look at the dashboard to get a summary: debit, credit.

## Bookkeeping Model

This application uses **double-entry bookkeeping**.

| Term | Definition |
|---|---|
| **Transaction** | A journal entry representing a real-world financial event (e.g., "bought groceries"). Contains two or more Mutations. |
| **Mutation** | A single line of a Transaction: one account plus a signed amount. All Mutation amounts within a Transaction sum to zero. |
| **Account** | An asset, liability, income, or expense bucket. Family bank accounts are `asset` accounts. Merchants are `expense` accounts. |

`account_type` can be `nil` while an imported account is still unclassified.

### Amount sign convention

- **Positive** amount on a Mutation = money flows *into* that account
- **Negative** amount on a Mutation = money flows *out of* that account

### Example: grocery purchase of €50

| Account | Amount |
|---|---|
| Assets:Checking (our bank account) | −50.00 |
| Expenses:Groceries (Albert Heijn) | +50.00 |
| **Sum** | **0.00** ✓ |

## Configuration

To setup a whitelist of urls, define `ENV["HOSTS"]` as a comma separated list.
Sending emails uses the `ENV["DEFAULT_HOST"]` variable
For example, in a .env file:

```
  HOSTS=foo.example.com, foo.example.test
  DEFAULT_HOST=foo.example.com
```

## Things todo when going to production

## Releasing

## Manually building image

Build the image using

```
docker build --build-arg RUBY_VERSION=$(cat .ruby-version) -t journal_administration .
```
