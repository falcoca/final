# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "bcrypt"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

locations_table = DB.from(:locations)
rikis_table = DB.from(:rikis)
areas_table = DB.from(:areas)
users_table = DB.from(:users)

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

get "/" do
    puts "params: #{params}"
    @areas = areas_table.all.to_a
    view "home"
end

get "/locations" do
    puts "params: #{params}"

    @locations = locations_table.all.to_a
    view "locations"
end

get "/locations/:id" do
    puts "params: #{params}"
    @locations = locations_table.all.to_a
    @location = locations_table.where(id: params[:id]).to_a[0]
    view "location"
end

get "/users/new" do
    view "new_user"
end

post "/users/create" do
    puts params
    hashed_password = BCrypt::Password.create(params["password"])
    users_table.insert(name: params["name"], email: params["email"], password: hashed_password)
    view "create_user"
end

get "/logins/new" do
    view "new_login"
end

post "/logins/create" do
    user = users_table.where(email: params["email"]).to_a[0]
    puts BCrypt::Password::new(user[:password])
    if user && BCrypt::Password::new(user[:password]) == params["password"]
        session["user_id"] = user[:id]
        @current_user = user
        view "create_login"
    else
        view "create_login_failed"
    end
end

get "/logout" do
    session["user_id"] = nil
    @current_user = nil
    view "logout"
end

get "/areas/:id" do
    @area = areas_table.where(id: params[:id]).to_a[0]
    @locations = locations_table.where(areas_id: @area[:id])
    view "area"
end

post "/rikis/submit" do
    puts params
    
    rikis_table.insert(purpose: params["purpose"], 
        rating: params["rating"], 
        comments: params["comments"])
    
    view "submit_riki"
end

post "/locations/submit" do
    puts params
    
    locations_table.insert(name: params["name"], 
        description: params["description"], 
        address: params["address"],
        areas_id: params["areas_id"])
    
    view "submit_area"
end