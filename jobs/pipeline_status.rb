#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'rubygems'
require 'json'

server = [
           {url: 'https://beta3.hub.jazz.net/pipeline/api/status', event: 'beta3_status'},
           {url: 'https://qa.hub.jazz.net/pipeline/api/status', event: 'qa_status'},
           {url: 'https://hub.jazz.net/pipeline/api/status', event: 'prod_status'}
         ]

SCHEDULER.every '120s', :first_in => 0 do |job|

    servers.each do |server|
        uri = URI.parse(server['url'])
        statuses = Array.new
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
                    arrow = "icon-ok-sign"
                    color = "green"
                else
                    arrow = "icon-warning-sign"
                    color = "red"
                end
                statuses.push({label: service, arrow: arrow, color: color})
            end
        end

        # print statuses to dashboard
        send_event(server['event'], {items: statuses})
    end
end
