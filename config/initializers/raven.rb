Raven.configure do |config|
  current_branch = case Rails.env.to_sym
                   when :staging then 'master'
                   else Rails.env
                   end

  config.dsn = 'https://afb8d771ad114eddbcd7b14546680ad0:4b94b49acc9b4c7cab58ab8a00dd9e15@sentry.io/1778246'

  config.environments = %w(staging production)
end
