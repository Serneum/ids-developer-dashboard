#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'rubygems'
require 'json'

ops = eval(File.open('options') {|f| f.read })

servers = [
            {url: ops[:dev_url] + '/build/api/json', event: 'devj_status'},
            {url: ops[:qa_url] + '/build/api/json', event: 'qaj_status'},
            {url: ops[:prod_url] + '/build/api/json', event: 'prodj_status'}
          ]

params = {
           :depth => ops[:depth],
           :tree => ops[:tree]
         }

SCHEDULER.every '120s', :first_in => 0 do |job|

    servers.each do |server|
        statuses = Array.new
        uri = URI.parse(server[:url])
        uri.query = URI.encode_www_form( params )
        http = Net::HTTP.new(uri.host, uri.port)
        if uri.scheme == "https"
            http.use_ssl=true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        request = Net::HTTP::Get.new(uri.request_uri)
        request.basic_auth ops[:username], ops[:password]
        begin
            response = http.request(request)
            if response.code == "200"
                begin
                    parsed = JSON.parse(response.body)
                    folders = parsed['jobs']
                    jobs = getAllJobs(folders)
                    for i in 0..9
                        job = jobs[i]
                        name = job['displayName']
                        status = job['lastBuild']['result']
                        if status == 'SUCCESS'
                            arrow = "icon-ok-sign"
                            color = "green"
                        else
                            arrow = "icon-warning-sign"
                            color = "red"
                        end
                        statuses.push({label: name, arrow: arrow, color: color})
                    end
                rescue JSON::ParserError
                    puts 'There was an error reading from ' + server[:url]
                end
            end

            # print statuses to dashboard
            send_event(server[:event], {items: statuses})
        rescue Timeout::error
            puts 'Server ' + server[:url] + ' took too long to respond'
        end
    end
end

def getAllJobs(json)
    jobsArray = Array.new
    json.each do |folder|
        jobs = folder['jobs']
        if !jobs.nil? && !jobs.empty?
            jobs.each do |job|
                if !job.nil? && !job.empty?
                    lastBuild = job['lastBuild']
                    if !lastBuild.nil? && !lastBuild.empty?
                        jobsArray.push(job)
                    end
                end
            end
        end
    end
    return jobsArray.sort_by{ |job| job['lastBuild']['timestamp'].to_i }.reverse!
end
