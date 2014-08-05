#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'rubygems'
require 'json'

ops = eval(File.open('options') {|f| f.read })

servers = [
            {url: ops[:dev_url] + '/pipeline/api/status', event: 'devp_status'},
            {url: ops[:qa_url] + '/pipeline/api/status', event: 'qap_status'},
            {url: ops[:prod_url] + '/pipeline/api/status', event: 'prodp_status'},
          ]

SCHEDULER.every '120s', :first_in => 0 do |job|

    servers.each do |server|
        statuses = Array.new
        uri = URI.parse(server[:url])
        http = Net::HTTP.new(uri.host, uri.port)
        if uri.scheme == "https"
            http.use_ssl=true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(request)
        services = JSON.parse(response.body)
        services.each do |service, data|
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

        # print statuses to dashboard
        send_event(server[:event], {items: statuses})
    end
end
