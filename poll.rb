require 'open-uri'
require "net/http"
require "uri"
require 'json'
require 'time'

require 'rubygems'
require 'bundler'
Bundler.require
Dotenv.load


require 'action_view'
include ActionView::Helpers::DateHelper

cache = Dalli::Client.new

doc = Nokogiri::HTML(open(ENV['KICKSTARTER_URL']))

title = doc.css('h2.normal.mb1 a').first.content

backers = doc.css('#backers_count').first['data-backers-count'].to_i
pledged = doc.css('#pledged data').first.content
target = doc.css('span.bold.h5 > .money.usd').first.content

pledged_i = pledged.gsub(/,|\$|£/, '').to_i
target_i = target.gsub(/,|\$|£/, '').to_i

if backers > 0
  old_count = cache.get('backer_count').to_i

  if old_count < backers

    payload= {
      text: "New Backers on <#{ENV['KICKSTARTER_URL']}|#{title}>",
      icon_url: "https://www.kickstarter.com/download/kickstarter-logo-k-color.png",
      channel: "##{ENV['SLACK_ROOM']}",
      username: 'Kickstarter',
      attachments: [
        {
          color: pledged_i > target_i ? '#2BDE73' : '#E3E4E6',
          fallback: "#{backers} backers, #{pledged} of #{target}",
          fields: [
            {
              title: 'Backers',
              value: backers,
              short: true
            },
            {
              title: 'Pledged',
              value: "#{pledged} of #{target}",
              short: true
            }
          ]
        }
      ]
    }

    puts JSON.dump(payload)
    puts URI.parse(ENV['SLACK_URL'])

    Net::HTTP.post_form(URI.parse(ENV['SLACK_URL']), {payload: JSON.dump(payload)})

    cache.set('backer_count', backers)

  end


end
