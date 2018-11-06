# Agile Central: Project Permissions Scripts

These scripts will retrieve and export Project-level permissions.

* Project TeamMembers: Exports team members for each project with the ability to filter by Role and enabled/disabled users

## Getting Started

### Prerequisites

Ensure ruby is installed. The script requires the following gems:

* [json](https://rubygems.org/gems/json)
* [rally_api](https://rubygems.org/gems/rally_api)
* [csv](https://rubygems.org/gems/csv)
* [logger](https://rubygems.org/gems/logger/versions/1.2.8)

### Installing & Running

1. Download or clone this repository
2. Update the config.json file:
   - **username/password OR api_key** (Required): Specify a valid username and password OR an API Key with sufficient, read-only access
   - **workspace** (Required): Specify a Workspace Name
   - **output_filename** (Required): Use the default provided filename or rename, if desired. Must contain the ".csv" extension
   - **role_types** (Required): List all roles to be included in the output. Available roles are "Admin", "User", "Viewer", "Editor". Example: ["Editor", "Viewer"]
   - **include_disabled_users** (Required): Include or exclude Disabled users in the output. Default is false, which excludes all disabled users.
3. Open terminal/console, navigate to the downloaded/cloned directory and run `ruby project_teammembers.rb config.json`

### Output

The .csv will contain the following data:

| Field/Heading          | Description                                                                                                                |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| ProjectName            | Name of the project for the team member                                                                                    |
| DisplayName            | Display name for the user                                                                                                  |
| LastName               | Last name for the user                                                                                                     |
| FirstName              | First name for the user                                                                                                    |
| EmailAddress           | Email address for the user                                                                                                 |
| Role                   | User role for the project (Admin, User, Viewer, Editor, SubAdmin)                                                          |
| Disabled               | Is the user account disabled (Yes or No)                                                                                   |
