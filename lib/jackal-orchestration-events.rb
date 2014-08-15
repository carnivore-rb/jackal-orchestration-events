require 'jackal'
require 'jackal-orchestration-events/version'

module Jackal
  module OrchestrationEvents

    autoload :Poll, 'jackal-orchestration-events/poll'
    autoload :Producer, 'jackal-orchestration-events/producer'

  end
end
