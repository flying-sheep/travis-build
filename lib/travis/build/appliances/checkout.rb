require 'travis/build/appliances/base'
require 'travis/build/git'

module Travis
  module Build
    module Appliances
      class Checkout < Base
        def apply
          Git.new(sh, data).checkout
        end
      end
    end
  end
end
