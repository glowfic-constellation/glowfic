Feature: Write New Post
As a author
I want to be able to write posts
So that I can glowfic

Scenario: Logged out user
When I start a new post
Then I should see "You must be logged in"
And I should not see "Create a new post"

Scenario: Logged in user
Given I am logged in
When I start a new post
Then I should see "Create a new post"
