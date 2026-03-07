# Base class for all Active Record models.
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
