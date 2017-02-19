require 'icalendar'
require 'csv'
require 'pry'

class Event

  attr_accessor :event
  attr_accessor :location
  attr_accessor :description
  attr_accessor :title
  attr_accessor :trip

  def initialize event
    @event = event
    self._process
  end

  def to_row
    # ["address", "title", "description", 'trip', "original_description"]
    p "#{start} #{@description}"
    [
      @location,
      "#{start} – #{location}",
      @description,
      @trip,
      @event.summary,
    ]
  end

  def start
    @event.dtstart.strftime(date_format)
  end

  def isElegible? previous_event
    /flight|stay|train|bus|boat/i.match(@event.summary) && is_long_enough?(previous_event) &&
    !/cancel/i.match(@event.summary)
  end

  def is_home?
    /genev|gva|zrh/i.match(@location)
  end

  def from_home?
    /genev|gva|zrh/i.match(@event.location) && /flight to /i.match(@event.summary)
  end

  def is_long_enough? previous_event
      return true if !previous_event
      p "#{@event.dtstart} - #{@event.dtstart} = #{(previous_event.dtend.to_time - @event.dtstart.to_time)} > 8"
      res = !previous_event || (@event.dtstart.to_time - previous_event.dtend.to_time)/3600 > 4

      res
  end

  def is_new_location_as? previous_event
    previous_event && /#{previous_event.location}/.match(event.location)
  end

  %W{summary dtstart dtend}.each do |method|
    define_method(method) { @event.send(method) }
  end

  def _process
    if /flight to /i.match(@event.summary)
      @location = /flight to (.*)/i.match(@event.summary)[1]
      @description = "Flight from #{@event.location} to #{@location}"
    else
      @description =  @event.summary
      @location = @event.location
    end
  end

  def date_format
    "%a %d %b %y"
  end

end


class Cal2MapCSV
  def initialize
    @events_count = 0
    @mapped_count = 0
    raw = nil
    # not working because the url doesn't return automatic events
    if ENV['WEB']
      system( 'curl https://calendar.google.com/calendar/exporticalzip?cexp=d2FsaWR2YkBnbWFpbC5jb20 -O cal_raw.ics')
    else
      url = ARGV[0]
    end

    cal_file = File.open(url)

    cals = Icalendar::Calendar.parse(cal_file)
    cal = cals.first

    CSV.open("file.csv", "wb") do |csv|
      csv << ["address", "title", "description", 'trip', "original_description"]
      @events_count = cal.events.size
      add_all_events cal.events, csv
    end
    p "#{@events_count} events found, #{@mapped_count} exported, #{@trips_count} trips found"

  end


  def add_all_events events, csv
    previous_event = nil
    @trips_count = 0
    events.sort_by(&:dtstart).each do |ev|
      event = Event.new ev
      if selected?(event, previous_event)
        if trip_started = @current_trip.nil? || event.from_home?
          @current_trip = @trips_count
          @trips_count += 1
        end
        if !event.is_new_location_as?(previous_event)
          event.trip = @current_trip
          csv << event.to_row
          @mapped_count+=1
        end
        previous_event = event
        if event.is_home?
          @current_trip = nil
        end
      end
    end
  end


  private

  def selected? event, previous_event
    event.isElegible?(previous_event) &&
      (location = event.location) &&
        !location.empty?
  end
end

Cal2MapCSV.new
