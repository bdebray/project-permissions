class RallyContext

    def Rally
        @rally
    end

    def initialize config_hash
            headers = RallyAPI::CustomHttpHeader.new({:name => "Blake DeBray", :version => "1.0"})

            config = {:rally_url => config_hash["rally_url"]}

            if (config_hash["api_key"].length > 0)
                config[:api_key]    = config_hash["api_key"]
            else
                config[:username]   = config_hash["username"]
                config[:password]   = config_hash["password"]
            end

            config[:workspace] = config_hash["workspace"]
            config[:headers]    = headers

            @rally = RallyAPI::RallyRestJson.new(config)
        end
    end