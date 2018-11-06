require 'rally_api'
require 'json'
require 'csv'
require 'logger'
require './rally_context'

class RallyTeamMembers

    User_Hash = {}
    
	def initialize configFile

		puts "Reading config file #{configFile}"
		puts "Connecting to rally"
		puts "Running in #{Dir.pwd}"

        file = File.read(configFile)
        config_hash = JSON.parse(file)
        
		@rally_context = RallyContext.new(config_hash)
      
		@csv_file_name = config_hash["output_filename"]
        @log_name = config_hash["log_name"]
        @role_types = config_hash["role_types"]
        
        if !@role_types.is_a?(Array)
            raise "role_types in #{file} is not valid. The values must be entered as an array"
        end
        
        @include_disabled_users = config_hash["include_disabled_users"]
        
		# Logger ------------------------------------------------------------
		@logger 			= Logger.new("./#{@log_name}")
		@logger.progname 	= "TeamMembers"
		@logger.level 		= Logger::DEBUG # UNKNOWN | FATAL | ERROR | WARN | INFO | DEBUG
	end
    
    def find_valid_projects
        
        query = RallyAPI::RallyQuery.new()
        query.type = "project"
        query.fetch = "Name,TeamMembers"
        query.order = "Name Asc"
        
        query.query_string = "(State = \"Open\")"
        
        return @rally_context.Rally.find(query)
    end
    
	def find_user(objectuuid)

        user = User_Hash[objectuuid]
        
        if (user != nil)
            return user
        end
        
		query = RallyAPI::RallyQuery.new()
		query.type = "user"
		query.fetch = "Name,ObjectID,UserName,EmailAddress,DisplayName,FirstName,LastName,Disabled,SubscriptionAdmin"
		query.page_size = 1
		query.limit = 1
		query.query_string = "(ObjectUUID = \"#{objectuuid}\")"

		results = @rally_context.Rally.find(query)
        user = results.first

        User_Hash[objectuuid] = user

        return user
	end
    
    def get_user_project_role(user, projectid)
        
        #no need to check ProjectPermissions; user is a SubAdmin
        if user["SubscriptionAdmin"] == true 
            return "SubAdmin"
        end
        
        #todo: do we need to check for WorkspaceAdmin?
        
        query = RallyAPI::RallyQuery.new()
        query.type = "projectpermissions"
        query.fetch = "Role"
        query.page_size = 1
		query.limit = 1
        
        query.query_string = "((Project.ObjectUUID = \"#{projectid}\") AND (User.ObjectUUID = \"#{user._refObjectUUID}\"))"
        
        result = @rally_context.Rally.find(query)
    
        permission = result.first
        
        return permission != nil ? permission["Role"] : "UNKNOWN"
    end
    
    def run
        start_time = Time.now
        
        projects = find_valid_projects
                
        puts "Found #{projects.length} projects"
		@logger.info "Found #{projects.length} projects\n"
        
        puts "Searching for #{@include_disabled_users == true ? "all" : "enabled"} team members that are #{@role_types.empty? ? "any role" : @role_types.join(",")}..."
            
        @logger.info "Searching for #{@include_disabled_users == true ? "all" : "enabled"} team members that are #{@role_types.empty? ? "any role" : @role_types.join(",")}...\n"
        
        CSV.open(@csv_file_name, "wb") do |csv|
			csv << ["ProjectName","DisplayName","LastName","FirstName","EmailAddress","Role","Disabled?"]
        
        projects.each { |project| 
            
            team_members = project["TeamMembers"]
            
            puts "Found #{team_members.length} team members for #{project["Name"]}"
            @logger.info "Found #{team_members.length} team members for #{project["Name"]}\n"
            
            team_members.each { |team_member| 
                
                #skip if we are excluding disabled users and the user is disabled
                next if !@include_disabled_users && team_member["Disabled"] == true

                role = get_user_project_role(team_member, project._refObjectUUID)
                
                #skip if we are filtering on any roles (role_types are not empty) and if the user's role does not match the filtered types
                next if !@role_types.empty? && !@role_types.include?(role)
                
                user = find_user(team_member._refObjectUUID)

                userdisplay = "(None)"
                user_last_name = ""
                user_first_name = ""
                team_member = false
                emaildisplay = "(None)"
                user_disabled = "UNKNOWN"

                if user != nil
                    userdisplay = user["DisplayName"] != nil ? user["DisplayName"] : user["EmailAddress"]
                    emaildisplay = user["EmailAddress"]
                    user_last_name = user["LastName"]
                    user_first_name = user["FirstName"]
                    user_disabled = user["Disabled"] == true ? "Yes" : "No"
                end

                csv << [project["Name"],userdisplay,user_last_name,user_first_name,emaildisplay,role,user_disabled]
                }
            }
        end
        
        print "Finished: elapsed time #{'%.1f' % ((Time.now - start_time)/60)} minutes."
		@logger.info "Finished: elapsed time #{'%.1f' % ((Time.now - start_time)/60)} minutes."
	end    
end

if (!ARGV[0])
	print "Usage: ruby workspace_admins.rb config_file_name.json\n"
	@logger.info "Usage: ruby workspace_admins.rb config_file_name.json\n"
else
	rtr = RallyTeamMembers.new ARGV[0]
	rtr.run
end