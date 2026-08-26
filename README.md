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

Background jobs are picked up by a supervisor running inside the web server. That
is on by default in development. Set `SOLID_QUEUE_IN_PUMA=false` to leave them to
a separate `bin/jobs` process instead.

## Things todo when going to production

Nothing by hand. `bin/start-app` runs `db:prepare` on every boot, so the extra
databases holding the cache, the job queue and live updates are created on the
first deploy that needs them.

Do check the volume. All four SQLite files live under `storage/db/`, which
`config/deploy.yml` mounts as persistent storage — without that mount every
deploy starts from an empty database.

## Releasing

## Manually building image

Build the image using

```
docker build --build-arg RUBY_VERSION=$(cat .ruby-version) -t journal_administration .
```
