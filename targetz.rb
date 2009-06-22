require 'sinatra'
require 'couchrest'
require 'haml'

DB = CouchRest.database!('http://localhost:5984/targetz')

class Target < CouchRest::ExtendedDocument
  use_database DB

  property :url
  property :slug
  property :desc

  view_by :slug
end

configure { set :haml, :attr_wrapper => '"' }

get '/' do
  @targets = Target.all.reverse
  haml :index
end

post '/' do
  args = params.delete_if {|k,v| ! %w[url desc slug].member?(k) }
  Target.new(args).save
  redirect '/'
end

get '/delete/:key' do
  Target.get(params[:key]).destroy
  redirect '/'
end

get '/__css__' do
  content_type 'text/css'
  File.read File.join(File.dirname(__FILE__), 'stylesheet.css')
end

get '/*' do
  target = Target.by_slug(:key => params[:splat].join('/')).first
  if target
    redirect target[:url]
  else
    redirect '/'
  end
end

use_in_file_templates!

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

#slugs
  %ul
    - @targets.each do |target|
      %li
        %a{:href => target[:url], :title => "View #{target[:url]}"}= target[:slug]
        %span.desc= target[:desc]
        %kbd= target[:url]
        .actions
          %a.delete{:href => "/delete/#{target["_id"]}", :title => 'Delete this target'} &#10007;
