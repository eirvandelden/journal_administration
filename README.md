# JournalAdministration

Fill in the journal with all your transactions. Look at the dashboard to get a summary: debit, credit.

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
