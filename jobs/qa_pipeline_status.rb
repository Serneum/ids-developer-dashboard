#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'rubygems'
require 'json'

server = 'https://qa.hub.jazz.net/pipeline/api/status'

SCHEDULER.every '90s', :first_in => 0 do |job|

    beta3_statuses = Array.new
    qa_statuses = Array.new
    prod_statuses = Array.new

    uri = URI.parse(server)
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.scheme == "https"
        http.use_ssl=true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    if response.code == "200"
        services = JSON.parse(response.body)
        services.each do |service, data|
            name = service
            status = data['status']
            if status == 'OK'
                result = 1
                arrow = "icon-ok-sign"
                color = "green"
                message = status
            else
                result = 0
                arrow = "icon-warning-sign"
                color = "red"
                message = data['message']
            end
            statuses.push({label: service, value: result, arrow: arrow, color: color})
        end
    end

    # print statuses to dashboard
    send_event('qa_status', {items: statuses})
end
