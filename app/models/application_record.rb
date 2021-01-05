class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def sgid
    to_sgid(expires_in: nil).to_s
  end
end
