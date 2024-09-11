require 'csv'
require 'date'

prs = CSV.read('pull_requests_data.csv', headers: true)

prs_by_month = prs.group_by { |pr| Date.parse(pr['Date']).strftime("%B %Y") }

File.open('deploy_stats_output.txt', 'w') do |file|
  prs_by_month.each do |month, month_prs|
    file.puts "\n## #{month}"
    month_prs.each do |pr|
      file.puts "#{pr['Repo']}: #{pr['PR Name']} (#{pr['Date']})"
    end
  end

  file.puts "\nTotal PRs: #{prs.size}"
end

puts "Deploy statistics have been saved to deploy_stats_output.txt"