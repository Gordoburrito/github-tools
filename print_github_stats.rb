require 'csv'
require 'set'

# Add this at the beginning of your script
FILTERED_AUTHORS = ["qooqu", "Gordoburrito", "BryantFukushima"] # Add the authors you want to keep

# Read and process the CSV data
pr_data = CSV.read('pull_requests_data.csv', headers: true)

# Initialize statistics
stats = {
  total_prs: 0,
  total_authors: Set.new,
  repo_data: Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = { count: 0, authors: Hash.new { |h3, k3| h3[k3] = [] } } } },
  prs_per_repo: Hash.new(0)
}

# Process the PR data
pr_data.each do |row|
  repo = row['Repo']
  author = row['Author']
  date = Date.parse(row['Date'])
  month = date.strftime("%Y-%m")
  pr_name = row['PR Name']
  pr_url = row['PR URL']

  stats[:total_prs] += 1
  stats[:total_authors].add(author)
  stats[:repo_data][repo][month][:count] += 1
  stats[:repo_data][repo][month][:authors][author] << { name: pr_name, url: pr_url, date: date }
  stats[:prs_per_repo][repo] += 1
end

# Generate HTML output
html_output = <<-HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GitHub PR Statistics</title>
    <style>
        body { font-family: Arial, sans-serif; }
        .collapsible { cursor: pointer; }
        .content { display: none; padding-left: 20px; }
        .arrow { display: inline-block; transition: transform 0.3s; }
        .arrow.open { transform: rotate(90deg); }
        .hidden { display: none; }
        .pr-link { 
            font-family: sans-serif; 
            text-decoration: none; 
            color: #0366d6;
            transition: color 0.2s ease-in-out;
        }
        .pr-link:hover {
            color: #0056b3;
            text-decoration: underline;
        }
        .pr-link:visited {
            color: #6f42c1;
        }
        .pr-link:visited:hover {
            color: #5a32a3;
        }
        .pr-date { font-size: 0.9em; color: #586069; margin-right: 10px; }
        ul { padding-left: 20px; }
        li { margin-bottom: 8px; }
    </style>
    <script>
        function toggleContent(id) {
            var content = document.getElementById(id);
            var arrow = document.getElementById(id + '_arrow');
            content.style.display = content.style.display === 'block' ? 'none' : 'block';
            arrow.classList.toggle('open');
        }

        function filterAuthors() {
            var select = document.getElementById('authorFilter');
            var selectedAuthors = Array.from(select.selectedOptions).map(option => option.value);
            var authorElements = document.getElementsByClassName('author');
            var monthHeadings = document.getElementsByClassName('month-heading');

            for (var i = 0; i < authorElements.length; i++) {
                var author = authorElements[i];
                if (selectedAuthors.includes(author.dataset.author) || selectedAuthors.length === 0) {
                    author.classList.remove('hidden');
                } else {
                    author.classList.add('hidden');
                }
            }

            updateMonthHeadings();
        }

        function updateMonthHeadings() {
            var monthHeadings = document.getElementsByClassName('month-heading');
            for (var i = 0; i < monthHeadings.length; i++) {
                var heading = monthHeadings[i];
                var monthContent = heading.nextElementSibling;
                var visibleAuthors = monthContent.querySelectorAll('.author:not(.hidden)');
                var authorNames = Array.from(visibleAuthors).map(author => author.dataset.author);
                var visiblePRs = monthContent.querySelectorAll('.author:not(.hidden) li').length;
                
                heading.querySelector('.visible-authors').textContent = '(' + authorNames.join(', ') + ')';
                heading.querySelector('.pr-count').textContent = visiblePRs;
                
                // Hide month heading if no visible authors
                if (visibleAuthors.length === 0) {
                    heading.classList.add('hidden');
                    monthContent.classList.add('hidden');
                } else {
                    heading.classList.remove('hidden');
                    monthContent.classList.remove('hidden');
                }
            }
        }
    </script>
</head>
<body>
    <h1>GitHub PR Statistics</h1>
    <p>Total PRs: #{stats[:total_prs]}</p>
    <p>Total unique authors: #{stats[:total_authors].size}</p>

    <label for="authorFilter">Filter Authors:</label>
    <select id="authorFilter" multiple onchange="filterAuthors()">
        <option value="">All Authors</option>
        #{stats[:total_authors].sort.map { |author| "<option value=\"#{author}\">#{author}</option>" }.join("\n        ")}
    </select>

    <h2>PRs per repository:</h2>
HTML

stats[:repo_data].each_with_index do |(repo, months), repo_index|
  html_output << <<-HTML
    <h3 class="collapsible" onclick="toggleContent('repo_#{repo_index}')">
        <span id="repo_#{repo_index}_arrow" class="arrow">▼</span> #{repo}: #{stats[:prs_per_repo][repo]} PRs
    </h3>
    <div id="repo_#{repo_index}" class="content">
  HTML

  months.sort.reverse.each_with_index do |(month, data), month_index|
    all_authors = data[:authors].keys.sort
    authors_list = all_authors.join(", ")
    
    html_output << <<-HTML
        <h4 class="collapsible month-heading" onclick="toggleContent('repo_#{repo_index}_month_#{month_index}')">
            <span id="repo_#{repo_index}_month_#{month_index}_arrow" class="arrow">▼</span> #{month}: <span class="pr-count">#{data[:count]}</span> PRs, #{all_authors.size} authors <span class="visible-authors">(#{authors_list})</span>
        </h4>
        <div id="repo_#{repo_index}_month_#{month_index}" class="content">
    HTML

    all_authors.each do |author|
      prs = data[:authors][author]
      next unless prs

      html_output << <<-HTML
            <div class="author" data-author="#{author}">
                <h5 class="collapsible" onclick="toggleContent('repo_#{repo_index}_month_#{month_index}_author_#{author}')">
                    <span id="repo_#{repo_index}_month_#{month_index}_author_#{author}_arrow" class="arrow">▼</span> #{author}: #{prs.size} PRs
                </h5>
                <div id="repo_#{repo_index}_month_#{month_index}_author_#{author}" class="content">
                    <ul>
      HTML

      prs.each do |pr|
        html_output << "                        <li><span class='pr-date'>#{pr[:date].strftime('%Y-%m-%d')}</span><a href='#{pr[:url]}' target='_blank' class='pr-link'>#{pr[:name]}</a></li>\n"
      end

      html_output << "                    </ul>\n                </div>\n            </div>\n"
    end

    html_output << "        </div>\n"
  end

  html_output << "    </div>\n"
end

html_output << "</body>\n</html>\n"

# Write HTML output to file
File.write('github_pr_stats.html', html_output)

puts "HTML report has been generated as 'github_pr_stats.html'"
