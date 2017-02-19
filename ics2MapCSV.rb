require 'icalendar'
require 'csv'
class Event

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

  def isAnArrival?
    /flight|stay|train/i.match(@event.summary)
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
    cal_file = File.open("cal.ics")
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
    last_location = "rdm"
    @trips_count = 0
    events.each do |ev|
      event = Event.new ev
      if selected? event
        if trip_started = @current_trip.nil?
          @current_trip = @trips_count
          @trips_count += 1
        end
        if !/#{last_location}/.match(event.location)
          event.trip = @current_trip
          add_event event, @current_trip, csv
          @mapped_count+=1
        end
        last_location = event.location
        if /genev|gva/i.match(last_location)
          @current_trip = nil
        end
      end
    end
  end


  private

  def add_event event, trip, csv,
    row = event.to_row
    csv << row
  end

  def selected? event
    event.isAnArrival? &&
      (location = event.location) &&
        !location.empty?
  end
end

caler = Cal2MapCSV.new
