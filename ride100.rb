#!/usr/bin/env ruby

require 'csv'
require 'open-uri'
require 'nokogiri'

class RideLondon

  def initialize
    @current_page = 1
    @url = 'http://results.prudentialridelondon.co.uk'
    @year = '2016'
  end

  def process
    results = []

    while @current_page
      scrape!

      riders.each do |rider|
        details = rider_details(rider)

        if details[4] == '100 Miles'
          results << details[0...headers.size]
        end
      end

      @current_page += 1
      sleep 1

      if no_more_results?
        @current_page = nil
      end
    end

    results = results.sort_by { |result| result.last.gsub(':','').to_i }

    CSV.open("ridelondon100.csv", "wb") do |csv|
      csv << headers.unshift('Position')
      results.each_with_index do |result, index|
        csv << result.unshift(index+1)
      end
    end
  end

  def scrape!
    puts "Checking: Page #{@current_page}"
    html = open(url)

    if html
      @doc = Nokogiri::HTML(html)
    end
  end

  private

  def headers
    ["Number", "Name", "AG", "Club", "Distance", "EST MILE 17", "EST MILE 26", "EST MILE 47", "EST MILE 55", "EST MILE 75", "EST MILE 85", "FINISH"]
  end

  def url
    File.join(@url, @year) + "?page=#{@current_page}&event=I&event_main_group=A&num_results=100&pid=list&search"
  end

  def no_more_results?
    message = @doc.css('.results-message').first
    !!(message && message.content == 'There are currently no results available.')
  end

  def riders
    @doc.css('table.list-table tbody tr')
  end

  def rider_details(rider)
    rider.css('td').map { |data| data.content }
  end
end

RideLondon.new.process
