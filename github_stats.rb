require 'dotenv'
require_relative 'github_data_processor'

# Load environment variables from .env file
Dotenv.load

# Initialize the GitHub client with your access token from the environment variable
access_token = ENV['GITHUB_ACCESS_TOKEN']
org_name = ENV['ORG_NAME']

repos = [
  'rooster-reminders-back-end',
  'rooster_reminders_front_end',
  'crm-thread',
  'openchair_widget',
  'thread-mobile'
  # Add more repos here
]

# Specify the end date (YYYY-MM-DD)
end_date = '2024-03-01'

processor = GithubDataProcessor.new(access_token, org_name, repos)
pr_data = processor.analyze_org_prs(end_date)

# Save the data to a CSV file
processor.save_pr_data_to_csv(pr_data, 'pull_requests_data.csv')

puts "GitHub stats have been fetched and saved to pull_requests_data.csv"
