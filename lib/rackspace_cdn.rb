#
# Copyright (c) 2009 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#
module Rightscale
  module Rackspace

    class CdnInterface < BaseInterface

      def initialize(username=nil, auth_key=nil, params={})
        params[:service_endpoint_key] = 'x-cdn-management-url'
        super username, auth_key, params
      end

      # The login is executed automatically when one calls any othe API call.
      # The only use case  for this method is when one need to pass any custom
      # headers or URL vars during a login process.
      #
      #  cdn.login #=> true
      #
      def login(opts={})
        authenticate(opts)
      end

      # List existing CDN-enabled Containers.
      # Params: :limit, :marker, :enabled_only
      #
      #  cdn.list_containers #=> 
      #    [{"name"=>"kd #1",
      #      "referrer_acl"=>"",
      #      "ttl"=>3600,
      #      "cdn_uri"=>"http://c0425742.cdn.cloudfiles.rackspacecloud.com",
      #      "log_retention"=>"false",
      #      "useragent_acl"=>"",
      #      "cdn_enabled"=>"true"},
      #     {"name"=>"photos",
      #      "referrer_acl"=>"",
      #      "ttl"=>10000,
      #      "cdn_uri"=>"http://c0428631.cdn.cloudfiles.rackspacecloud.com",
      #      "log_retention"=>"false",
      #      "useragent_acl"=>"",
      #      "cdn_enabled"=>"true"}]
      #
      #   # get first container only
      #   cdn.list_containers(:limit => 1)
      #
      #   # get enabled containers only
      #   cdn.list_containers(:enabled_only => true)
      #
      # TODO: why does Rackspace return boolean params as string here?
      #
      def list_containers(params={}, opts={})
        add_fields(opts, :vars, params.merge(:format => 'json'), :override)
        api_or_cache(:get, "/", opts)
      end

      # Incrementally list containers
      # Params: :limit, :marker, :enabled_only
      #
      #  # list containers by 10
      #  cdn.incrementally_list_containers(:limit => 10) do |containers|
      #    puts containers.inspect
	    #    true # continue listing
      #  end
      #
      def incrementally_list_containers(params={}, opts={}, &block)
        add_fields(opts, :vars, params.merge(:format => 'json'), :override)
        incrementally_list_storage_resources(:get, "/", opts, &block)
      end

      # Share a container.
      # Params: :ttl, :cdn_enabled, :log_retention
      #
      #  cdn.share_container("my_awesome_container") #=>  http://c0425002.cdn.cloudfiles.rackspacecloud.com
      #
      def share_container(container_name, params={}, opts={})
        share_or_update_container(:put, container_name, params, opts)
      end

      # Describe CND-enabled container data.
      #
      #  cdn.describe_container("my_awesome_container")
      #    {"referrer_acl"=>"",
      #     "ttl"=>10000,
      #     "cdn_uri"=>"http://c0425002.cdn.cloudfiles.rackspacecloud.com",
      #     "log_retention"=>false,
      #     "cdn_enabled"=>false,
      #     "user_agent_acl"=>""}
      #
      def describe_container(container_name, opts={})
        api(:head, "/#{URI.escape container_name}", opts)
        underscorize_response_keys(extract_response_keys(@last_response.to_hash, /\Ax-(.*)\Z/))
      end

      # Change CND-enabled container data.
      # Params: :ttl, :cdn_enabled, :log_retention
      #
      #  cdn.update_container("my_awesome_container", :ttl=>5000, :cdn_enabled=>true) #=>  http://c0425002.cdn.cloudfiles.rackspacecloud.com
      #
      def update_container(container_name, params={}, opts={})
        share_or_update_container(:post, container_name, params, opts)
      end

    private

      def share_or_update_container(http_verb, container_name, params={}, opts={}) # :nodoc:
        add_fields(opts, :headers, underscorize_response_keys(params, :reverse), :override, 'x-')
        api(http_verb, "/#{URI.escape container_name}", opts)
        @last_response['X-CDN-URI']
      end

    end
  end
end