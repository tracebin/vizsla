module Tracebin
  class Config
    DEFAULTS = {
      log_level: 'info',
      host: 'https://traceb.in',
      report_path: 'reports',
      enable_ssl: true,
      ignored_paths: [],
      enabled: true,
      report_frequency: 60,
      report_retry_limit: 10
    }.freeze

    attr_accessor *(DEFAULTS.keys + [:bin_id])

    def initialize(config = {})
      opts = DEFAULTS.merge config
      opts.keys.each do |key|
        if self.respond_to? key
          self.instance_variable_set "@#{key}", opts[key]
        end
      end
    end
  end
end
