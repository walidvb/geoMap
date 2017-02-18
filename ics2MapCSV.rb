require 'icalendar'
require 'csv'


class Cal2MapCSV

  def run
    @events_count = 0
    @mapped_count = 0
    cal_file = File.open("cal.ics")
    cals = Icalendar::Calendar.parse(cal_file)
    cal = cals.first
    now = Date.today
    CSV.open("file.csv", "wb") do |csv|
      csv << ["address", "title", "description", 'original_summary']
      @events_count = cal.events.size
      add_all_events cal.events, csv
    end
    p "#{@events_count} events found, #{@mapped_count} imported”"

  end


  def add_all_events events, csv
    last_location = "rdm"
    events.each do |event|
      if selected? event
        p "#{last_location} | #{get_location(event)}"
        if !/#{last_location}/.match(get_location(event))
          add_event event, csv
          @mapped_count+=1
        end
        last_location = get_location(event)
      end
    end
  end


  private

  def add_event event, csv
    sum = event.summary
    row = [
      get_location(event),
      event.dtstart.strftime("%a %d %b %y"),
      event.summary,
      sum
    ]
    csv << row
  end

  def selected? event
    /flight|stay/i.match(event.summary) &&
      (location = event.location) &&
        !location.empty?
  end

  def get_location event
    if /flight to /i.match(event.summary)
      real_location = /flight to (.*)/i.match(event.summary)[1]
      event.summary = "Flight from #{real_location} to #{event.location}"
      real_location
    else
      event.location
    end
  end
end

caler = Cal2MapCSV.new
caler.run
