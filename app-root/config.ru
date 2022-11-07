# frozen_string_literal: true


#    This file is used by Rack-based servers to start the application.
require ::File.expand_path('../config/environment', __FILE__)


run Rails.application

####################################################

require_relative './ndt_global.rb'
require_relative './monkeypatch1.rb'

ensure_exists_admin( ..)

=begin
so many logging solutions they cancel each other out
Rails.logger.debug('confirm LOGGER.DEBUG USE : now in config.ru ~~~~~~~~~~~~~~~~~~~~~~~~')
=end
