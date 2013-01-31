require 'sauce/software/base'
require 'sauce/software/service'
module Sauce
  module Software
    # Redis Server
    class Redis < Software::Base
      @software_name = "redis"
      @software_command = "redis-server"
      include Service

    end
  end
end
