#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'date'
require 'kafka'

@name = "malagabus2k"
@zone = ENV['ZONE'].nil? ? "CEST" : ENV['ZONE']
url = ENV['URL'].nil? ? "http://datosabiertos.malaga.eu/recursos/transporte/EMT/EMTlineasUbicaciones/lineasyubicaciones.geojson" : ENV['URL']
@time = ENV['TIME'].nil? ? 10 : ENV['TIME']
kafka_broker = ENV['KAFKA_BROKER'].nil? ? "127.0.0.1" : ENV['KAFKA_BROKER']
kafka_port = ENV['KAFKA_PORT'].nil? ? "9092" : ENV['KAFKA_PORT']
@kafka_topic = ENV['KAFKA_TOPIC'].nil? ? "malagabus" : ENV['KAFKA_TOPIC']
kclient = Kafka.new(seed_brokers: ["#{kafka_broker}:#{kafka_port}"], client_id: "malagabus2k")

def w2k(url,kclient)
    lastasset = {}
    lastdigest = ""
    puts "[#{@name}] Starting malagabus poc thread"
    while true
        begin
            puts "[#{@name}] Connecting to #{url}" unless ENV['DEBUG'].nil?
            busjson = Net::HTTP.get(URI(url))
            next if lastdigest == Digest::MD5.hexdigest(busjson)
            bushash = JSON.parse(busjson)
            bushash.each do |bus|
                timestamp = DateTime.parse("#{bus["properties"]["last_update"].to_s} #{@zone}").to_time.to_i
                unless lastasset["#{bus["codBus"]}"].nil?
                    next if lastasset["#{bus["codBus"]}"] == timestamp
                end
                lastasset["#{bus["codBus"]}"] = timestamp
                puts "New data from bus_id: #{bus["codBus"]}, timestamp: #{timestamp}" unless ENV['DEBUG'].nil?
                bus["timestamp"] = timestamp
                bus["latitude"] = "#{bus["geometry"]["coordinates"][1]}"
                bus["longitude"] = "#{bus["geometry"]["coordinates"][0]}"
                #puts "bus asset: #{JSON.pretty_generate(bus)}\n" unless ENV['DEBUG'].nil?
                kclient.deliver_message("#{bus.to_json}",topic: @kafka_topic)
            end

            sleep @time
        rescue Exception => e
            puts "Exception: #{e.message}"

        end
    end

end


Signal.trap('INT') { throw :sigint }

catch :sigint do
        t1 = Thread.new{w2k(url,kclient)}
        t1.join
end

puts "Exiting from malagabus2k"

## vim:ts=4:sw=4:expandtab:ai:nowrap:formatoptions=croqln:
