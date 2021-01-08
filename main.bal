import ballerina/config;
import ballerina/io;
import ballerinax/github;

github:GitHubConfiguration gitHubConfig = {accessToken: config:getAsString("app.github.access_token")};

github:Client githubClient = new (gitHubConfig);

string REPOSITORY_NAME = "ballerina-platform/ballerina-lang";

public function main() {
    // Retrieves all of the opened issues in the target repository.
    github:Issue[] allOpenIssues = getAllOpenIssues(REPOSITORY_NAME);
    // Extracts the dev tools issues from the open issues.
    github:Issue[] devToolsIssues = filterDevToolsIssues(allOpenIssues);
    // Outputs the summary of all open dev tools issues to a text file.
    generateSummary(allOpenIssues, devToolsIssues);
}

public function getAllOpenIssues(string repository) returns @tainted github:Issue[] {

    github:Issue[] allIssues = [];
    int curIndex = 0;

    github:Repository|error repoResponse = githubClient->getRepository("ballerina-platform/ballerina-lang");

    if (repoResponse is github:Repository) {
        var issuesResponse = githubClient->getIssueList(repoResponse, github:STATE_OPEN, 100);
        while (issuesResponse is github:IssueList && curIndex < 200) {
            foreach var issue in issuesResponse.getAllIssues() {
                allIssues[curIndex] = issue;
                curIndex += 1;
            }
            issuesResponse = githubClient->getIssueListNextPage(issuesResponse);
        }
    } else {
        io:println("Error occurred while fetching repository information: ", repoResponse);
    }
    return allIssues;
}

public function filterDevToolsIssues(github:Issue[] issues) returns github:Issue[] {
    github:Issue[] result = [];

    foreach var issue in issues {
        foreach var label in issue.labels {
            if (label.name == "Team/DevTools") {
                result.push(issue);
            }
        }
    }
    return result;
}

public function generateSummary(github:Issue[] allOpenIssues, github:Issue[] devToolsIssues) {
    string[] summary = [];

    summary.push("Github Issue Summary: " + REPOSITORY_NAME);
    summary.push("");
    summary.push("Total open issues: " + allOpenIssues.length().toBalString());
    summary.push("Total open dev-tools issues: " + allOpenIssues.length().toBalString());
    summary.push("");

    foreach var issue in devToolsIssues {
        summary.push(string `ID: ${issue.id}, Title: ${issue.title}`);
    }

    string outputFilePath = "output/summary.txt";
    var fileWriteLines = io:fileWriteLines(outputFilePath, summary);
}
