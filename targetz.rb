require 'sinatra/base'
require 'couchrest'
require 'haml'

class Targetz < Sinatra::Base

  Errors = {
    1 => %q{There is already a target with this slug},
    2 => %q{Unknown slug}
  }

  configure do
    set :haml, :attr_wrapper => '"'
    set :database, Proc.new {
      CouchRest.database!('http://localhost:5984/targetz')
    }
  end

  get '/' do
    @targets = Target.all.reverse
    @error   = Errors[params[:error].to_i] if params[:error]
    haml :index
  end

  post '/' do
    targets = Target.by_slug(:key => params[:slug])
    if targets.empty?
      args = params.delete_if {|k,v| ! %w[url desc slug].member?(k) }
      Target.new(args).save
      redirect '/'
    else redirect '/?error=1' end
  end

  delete '/' do
    target = Target.by_slug(:key => params[:slug]).first
    if target
      target.destroy
      redirect '/'
    else redirect '/?error=2' end
  end

  get '/__css__' do
    content_type 'text/css'
    File.read File.join(File.dirname(__FILE__), 'stylesheet.css')
  end

  get '/*' do
    target = Target.by_slug(:key => params[:splat].join('/')).first
    if target
      redirect target[:url]
    else redirect '/' end
  end

  use_in_file_templates!

end

class Target < CouchRest::ExtendedDocument
  use_database Targetz.database

  property :url
  property :slug
  property :desc

  view_by :slug
end

__END__

@@ layout
!!! Strict
%html
  %head
    %title Targetz
    %link{:href => '/__css__', :rel => 'stylesheet', :media => 'screen', :type => 'text/css'}
  %body
    = yield

@@ index
%h1 Targetz

%form{:action => '/', :method => 'POST'}
  %ul#form
    %li#slug_li
      %input{:type => 'text', :id => 'slug', :name => 'slug', :value => "Target"}
    %li#url_li
      %input{:type => 'text', :id => 'url', :name => 'url', :value => "http://"}
    %li#desc_li
      %input{:type => 'text', :id => 'desc', :name => 'desc', :value => "Description"}
    %li#submit_li
      %input{:type => 'submit', :value => 'Add'}

- if @error
  %p#error= @error

#slugs
  %ul
    - @targets.each do |target|
      %li
        %a{:href => target[:url], :title => "View #{target[:url]}"}= target[:slug]
        %span.desc= target[:desc]
        %kbd= target[:url]
        .actions
          %form{:action => '/', :method => 'POST'}
            %input{:type => 'hidden', :name => '_method', :value => 'DELETE'}
            %input{:type => 'hidden', :name => 'slug', :value => target[:slug]}
            %input{:type => 'submit', :id => 'delete', :value => '&#10007;'}

@@ already_exists
%p.error
  There is already a target with this slug
