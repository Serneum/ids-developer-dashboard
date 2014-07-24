#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'rubygems'
require 'json'

# Check whether a server is responding
# you can set a server to check via http request or ping
#
# server options:
# name: how it will show up on the dashboard
# url: either a website url or an IP address (do not include https:// when usnig ping method)
# method: either 'http' or 'ping'
# if the server you're checking redirects (from http to https for example) the check will
# return false

servers = {beta3: 'https://beta3.hub.jazz.net/pipeline/api/status', qa: 'https://qa.hub.jazz.net/pipeline/api/status', prod: 'https://hub.jazz.net/pipeline/api/status'}

SCHEDULER.every '90s', :first_in => 0 do |job|

    beta3_statuses = Array.new
    qa_statuses = Array.new
    prod_statuses = Array.new
    
    uri = URI.parse(servers[:beta3])
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
            beta3_statuses.push({label: service, value: result, arrow: arrow, color: color})
        end
    end

    uri = URI.parse(servers[:qa])
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
            qa_statuses.push({label: service, value: result, arrow: arrow, color: color})
        end
    end

    uri = URI.parse(servers[:prod])
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
            prod_statuses.push({label: service, value: result, arrow: arrow, color: color})
        end
    end

    # print statuses to dashboard
    send_event('beta3_status', {items: beta3_statuses})
    send_event('qa_status', {items: qa_statuses})
    send_event('prod_status', {items: prod_statuses})
end