require 'octokit'
require 'date'
require 'csv'

class GithubDataProcessor
  def initialize(access_token, org_name, repos)
    @client = Octokit::Client.new(access_token: access_token)
    @org_name = org_name
    @repos = repos
  end

  def analyze_org_prs(end_date)
    pr_data = []
    end_date = Date.parse(end_date)

    @repos.each do |repo|
      page = 1
      loop do
        prs = @client.pull_requests("#{@org_name}/#{repo}", state: 'all', per_page: 100, page: page)
        break if prs.empty?

        prs.each do |pr|
          pr_date = pr.created_at.to_date
          break if pr_date < end_date

          pr_info = {
            repo: repo,
            name: pr.title,
            author: pr.user.login,
            date: pr_date.strftime('%Y-%m-%d'),
            url: pr.html_url  # Add this line to include the PR URL
          }
          pr_data << pr_info
        end

        break if prs.last.created_at.to_date < end_date
        page += 1
      end
    end

    pr_data.sort_by { |pr| Date.parse(pr[:date]) }.reverse
  end

  def save_pr_data_to_csv(pr_data, filename)
    CSV.open(filename, 'w') do |csv|
      csv << ['Repo', 'PR Name', 'Author', 'Date', 'PR URL']  # Add 'PR URL' to the header
      pr_data.each do |pr|
        csv << [pr[:repo], pr[:name], pr[:author], pr[:date], pr[:url]]  # Include pr[:url] in the CSV output
      end
    end
    puts "PR data saved to #{filename}"
  end

  def process_pr_data(pr_data)
    total_prs = pr_data.size
    authors = pr_data.map { |pr| pr[:author] }.uniq
    total_authors = authors.size
    prs_per_repo = pr_data.group_by { |pr| pr[:repo] }.transform_values(&:size)

    repo_data = pr_data.each_with_object({}) do |pr, hash|
      date = Date.parse(pr[:date])
      month_key = date.strftime("%Y-%m")
      hash[pr[:repo]] ||= {}
      hash[pr[:repo]][month_key] ||= { count: 0, authors: Hash.new { |h, k| h[k] = [] } }
      hash[pr[:repo]][month_key][:count] += 1
      hash[pr[:repo]][month_key][:authors][pr[:author]] << { name: pr[:name], url: pr[:url] }
    end

    {
      total_prs: total_prs,
      total_authors: total_authors,
      prs_per_repo: prs_per_repo,
      repo_data: repo_data
    }
  end
end
