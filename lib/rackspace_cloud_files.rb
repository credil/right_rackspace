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

    class CloudFilesInterface < BaseInterface

      def initialize(username=nil, auth_key=nil, params={})
        params[:service_endpoint_key] = 'x-storage-url'
        super username, auth_key, params
      end

      # The login is executed automatically when one calls any othe API call.
      # The only use case  for this method is when one need to pass any custom
      # headers or URL vars during a login process.
      #
      #  storage.login #=> true
      #
      def login(opts={})
        authenticate(opts)
      end

      # Describe a storage (retrieve the number of Containers and the total bytes
      # stored in Cloud Files for the account)
      #
      #   storage.describe_storage #=> {"container_count"=>2, "bytes_used"=>2000052}
      #
      def describe_storage(opts={})
        api(:head, "/", opts)
        underscorize_response_keys( extract_response_keys(@last_response.to_hash, /\Ax-account-(.*)\Z/) )
      end  

      #--------------------------------
      # Containers
      #--------------------------------

      # List all Containers.
      # Returns max 10000 containers.
      # Params: :limit, :marker and :prefix(is not supported yet by Rackspace)
      #
      #  # get all containers
      #  rackspace.list_containers #=>
      #    [{"bytes"=>2000052, "name"=>"kd #1", "count"=>6},
      #     {"bytes"=>0, "name"=>"photos", "count"=>0},
      #     {"bytes"=>0, "name"=>"pictures", "count"=>0}]
      #
      #  # get the first container
      #  storage.list_containers(:limit => 1)
      #    [{"bytes"=>2000052, "name"=>"kd #1", "count"=>6}]
      #
      #  # get all containers after a container "kd #1"
      #  storage.list_containers(:marker => 'kd #1') #=>
      #    [{"bytes"=>0, "name"=>"photos", "count"=>0},
      #     {"bytes"=>0, "name"=>"pictures", "count"=>0}]
      #
      def list_containers(params={}, opts={})
        add_fields(opts, :vars, params.merge(:format => 'json'), :override)
        api(:get, "/", opts)
      end

      # Incrementally list containers.
      # Params: :limit, :marker and :prefix(is not supported yet by Rackspace)
      #
      #  # list containers by 1
      #  storage.incrementally_list_containers(1) do |containers|
      #    puts containers.inspect #=> [{"bytes"=>2000052, "name"=>"kd #1", "count"=>6}]
      #    true # continue listing
      #  end
      #
      def incrementally_list_containers(params={}, opts={}, &block)
        add_fields(opts, :vars, params.merge(:format => 'json'), :override)
        incrementally_list_storage_resources(:get, "/", opts, &block)
      end

      # Create a container.
      #
      #  storage.create_container("my_container") #=> true
      #
      def create_container(container_name, opts={})
        api(:put, "/#{URI.escape container_name}", opts)
      end

      # Determine the number of Objects, and the total bytes of all Objects stored in the Container
      #
      #  storage.describe_container("my_container") #=> {"object_count"=>6, "bytes_used"=>2000052}
      #
      def describe_container(container_name, opts={})
        api(:head, "/#{URI.escape container_name}", opts)
        underscorize_response_keys( extract_response_keys(@last_response.to_hash, /\Ax-container-(.*)\Z/) )
      end

      # Delete a container.
      #
      #  storage.delete_container("my_container") #=> true
      #
      def delete_container(container_name, opts={})
        api(:delete, "/#{URI.escape container_name}", opts)
      end

      #--------------------------------
      # Objects
      #--------------------------------

      # List objects.
      # Params: :prefix, :path, :limit and :marker
      #
      #  # list all objects
      #  storage.list_objects("kd #1") #=>
      #    {"bytes"=>6,
      #      "name"=>"kd1",
      #      "content_type"=>"text/plain",
      #      "hash"=>"a64cee333c5424f771ebb72d525bdb90",
      #      "last_modified"=>"2009-11-10T08:43:01.209444"},
      #      ...
      #     {"bytes"=>41,
      #      "name"=>"kd3/4/77",
      #      "content_type"=>"text/plain",
      #      "hash"=>"d7eff10d9be4f98868be92ce6c10c54b",
      #      "last_modified"=>"2009-11-10T08:44:27.262372"}]
      #
      #  # list all objects with names beginning with 'kd3'
      #  storage.list_objects("kd #1", :prefix => 'kd3') #=>
      #    [{"bytes"=>0,
      #      "name"=>"kd3",
      #      "content_type"=>"application/directory",
      #      "hash"=>"d41d8cd98f00b204e9800998ecf8427e",
      #      "last_modified"=>"2009-11-10T13:23:41.778432"},
      #      ...
      #      "name"=>"kd3/4/77",
      #      "content_type"=>"text/plain",
      #      "hash"=>"d7eff10d9be4f98868be92ce6c10c54b",
      #      "last_modified"=>"2009-11-10T08:44:27.262372"}]
      #
      #  # list all object nested in the pseudo path 'kd3'
      #  storage.list_objects("kd #1", :path => 'kd3') #=>
      #    [{"bytes"=>0,
      #      "name"=>"kd3/4",
      #      "content_type"=>"application/directory",
      #      "hash"=>"d41d8cd98f00b204e9800998ecf8427e",
      #      "last_modified"=>"2009-11-10T13:23:42.309523"}]
      #
      #  # list 2 objects with prefix 'kd3' after object 'kd3/4'
      #  storage.list_objects("kd #1", :prefix => 'kd3', :limit => 2, :marker => 'kd3/4') #=>
      #      [{"bytes"=>5,
      #        "name"=>"kd3/4/17.txt",
      #        "content_type"=>"text/plain",
      #        "hash"=>"67041760686d094b722b332553033178",
      #        "last_modified"=>"2009-11-10T13:25:04.841459"},
      #       {"bytes"=>41,
      #        "name"=>"kd3/4/77",
      #        "content_type"=>"text/plain",
      #        "hash"=>"d7eff10d9be4f98868be92ce6c10c54b",
      #        "last_modified"=>"2009-11-10T08:44:27.262372"}]
      #
      def list_objects(container_name, params={}, opts={})
        add_fields(opts, :vars, params.merge(:format => 'json'), :override)
        api(:get, "/#{URI.escape container_name}", opts)
      end

      # Incrementally list objects.
      # Params: :prefix, :path, :limit and :marker
      #
      #  # list objects by 2
      #  storage.incrementally_list_objects('kd #1', :limit => 2) do |objects|
      #    puts objects.inspect #=>  [{"bytes"=>6,
      #                                "name"=>"kd1",
      #                                "content_type"=>"text/plain",
      #                                "hash"=>"a64cee333c5424f771ebb72d525bdb90",
      #                                "last_modified"=>"2009-11-10T08:43:01.209444"},
      #                               {"bytes"=>2000000,
      #                                "name"=>"kd2",
      #                                "content_type"=>"text/plain",
      #                                "hash"=>"e8337865e1aecea14cfea1f67477fa1a",
      #                                "last_modified"=>"2009-11-10T14:25:41.788011"}]
      #    true # continue listing
      #  end
      #
      def incrementally_list_objects(container_name, params={}, opts={}, &block)
        add_fields(opts, :vars, params.merge(:format => 'json'), :override)
        incrementally_list_storage_resources(:get, "/#{URI.escape container_name}", opts, &block)
      end

      # Create a new object.
      #
      #  storage.create_object("my_container", "kd #1", 'Hello world', {'tag1' => 'woo-hoo', 'tag2' => 'ohohoh'}) #=> true
      #
      def create_object(container_name, object_name, object_data, meta_data={}, content_type='text/plain', opts={})
        add_fields(opts, :headers, 'content-type' => content_type )
        add_fields(opts, :headers, meta_data, :override, 'x-object-meta-')
        opts[:body] = object_data.to_s
        api(:put, "/#{URI.escape container_name}/#{URI.escape object_name}", opts)
      end

      # Get object metadata.
      #
      #  storage.describe_object("my_container", "kd #1") #=> {'tag3' => 'blah-blah'}
      #
      def describe_object(container_name, object_name, opts={})
        api(:head, "/#{URI.escape container_name}/#{URI.escape object_name}", opts)
        extract_response_keys(@last_response.to_hash, /\Ax-object-meta-(.*)\Z/)
      end

      # Update object metadata.
      #
      #  storage.update_metadata("my_container", "kd #1", {'tag3' => 'blah-blah'}) #=> true
      #
      def update_metadata(container_name, object_name, meta_data={}, opts={})
        add_fields(opts, :headers, meta_data, :override, 'x-object-meta-')
        api(:post, "/#{URI.escape container_name}/#{URI.escape object_name}", opts)
      end

      # Get object data and metadata.
      # Params: :range, :if_match, :if_none_match, :if_modified_since, :if_unmodified_since
      #
      #  storage.get_object_with_meta_data("my_container", "kd #1") #=> ["Hello world", {'tag3' => 'blah-blah'}]
      #
      def get_object_with_meta_data(container_name, object_name, params={}, opts={})
        prepare_get_object_data(params, opts)
        object    = api(:get, "/#{URI.escape container_name}/#{URI.escape object_name}", opts)
        meta_data = extract_response_keys(@last_response.to_hash, /\Ax-object-meta-(.*)\Z/)
        [object, meta_data]
      end

      # Get object data.
      # Params: :range, :if_match, :if_none_match, :if_modified_since, :if_unmodified_since
      #
      #  # Get object
      #  storage.get_object("my_container", "kd #1") #=> "Hello world"
      #
      #  # Streamed output (for huge objects)
      #  x = File::new('/tmp/test.jpg', "w")
      #  storage.get_object("my_container", "photo1.jpg") do |chunk|
      #    x.write(chunk)
      #  end
      #  x.close
      #
      def get_object(container_name, object_name, params={}, opts={}, &block)
        prepare_get_object_data(params, opts)
        api(:get, "/#{URI.escape container_name}/#{URI.escape object_name}", opts, &block)
      end

      # Delete object.
      #
      #  storage.delete_object("my_container", "kd #1") #=> true
      #
      def delete_object(container_name, object_name, opts={})
        api(:delete, "/#{URI.escape container_name}/#{URI.escape object_name}", opts)
      end

    private
    
      def prepare_get_object_data(params, opts) # :nodoc:
        opts[:do_not_parse_response] = true
        params = underscorize_response_keys(params, :reverse).merge('accept' => '*/*')
        # fix 'If-[Un]modified-since' field
        ['if-modified-since', 'if-unmodified-since'].each do |header|
          params[header] = params[header].httpdate if params[header].is_a?(Time)
        end
        # fix 'Range' header
        if params['range'] && params['range'][/\A\d+-|-\d+|\d+-\d+\Z/]
          params['range'] = "bytes=#{params['range']}"
        end
        add_fields(opts, :headers, params)
      end
      
    end
  end
end