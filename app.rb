#!/usr/bin/env ruby

=begin

***OVERVIEW***

When clients sign up for the service, they develop a 1:1 relationship with a wellness
coach over the course of a year. These coaches help them interpret their personal health data as 
well as make actionable recommendations to improve a client's overall wellness. 

Clients need to schedule coaching calls on a monthly basis.

We want to create a web based experience that makes it easy for clients to schedule a call.

Clients should be able to see their coach's availability and then book an hour long coaching slot.

Once a slot is booked, other clients should not be able to book that slot with the same coach.

***IMPORTANT DETAILS***

- User has an assigned coach.
- User has a 1 year long membership.
- User can't have more than 1 appointment per month.
- Coach has a set of available time slots.


***TODO**

1. Change/cancel appointments.
2. Add some sort of reminder - email?
3. Sync with external calendars - fullcalendar supports Google Calendar.
4. Run over https.

=end

require 'sinatra'
require 'sinatra/flash'
require 'haml'
require 'sinatra/activerecord'

#require 'rack/ssl-enforcer'
#use Rack::SslEnforcer, :except_hosts => /localhost:4568/

class User < ActiveRecord::Base
  has_secure_password
end

class Coach < ActiveRecord::Base
end

class Appointment < ActiveRecord::Base
end

set :port, 4568
enable :sessions

def build_appointments(user)
  temp_hash = {}
  $appointment_events=[]
  $appointments.each do |a|
    temp_hash={title: "Booked Slot", start: "#{a.start_time}", end: "#{a.end_time}", description: "Occupied Slot"}
    # allow user to modify their own uncompleted appointments in calendar
    if a.user_id == user.id && !a.completed
      temp_hash.merge!({title: "Your Session", editable: "true", backgroundColor: "yellow", textColor: "black", description: "You have a call with #{$user_coach} at this time!"})
    end
    $appointment_events<<temp_hash
  end
end

get '/' do
  haml :home
end

post '/login' do
  $user = User.find_by_email(params[:email])
  if $user && $user.authenticate(params[:password])
    $user_coach =  Coach.find($user[:coach_id])[:name]
    r = Appointment.where("coach_id = ?", $user[:coach_id]).all
    $appointments = r.to_a
    build_appointments($user)
    redirect '/scheduler'
  else
    # decided not to include 'right username but wrong password message for paranoia's sake'
    flash[:error] = "Incorrect email or password."
    redirect '/'
  end
end

get '/scheduler' do
  haml :scheduler2, :locals => {:appointments => $appointments}
end

get '/resetpass' do
  redirect '/'
end
