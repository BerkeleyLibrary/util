class RetryDelayTooLarge < RestClient::Exception
  def initialize(response, delay:, max_delay:)
    super(response, response.code)

    self.message = 'Retry delay of %0.2gs exceeds limit of %0.2gs' % [delay, max_delay]
  end
end

class RetryLimitExceeded < RestClient::Exception
  def initialize(response, max_retries:)
    super(response, response.code)

    self.message = "Retry limit (#{max_retries}) exceeded"
  end
end
