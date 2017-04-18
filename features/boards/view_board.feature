Feature: View Board
As a reader
I want to be able to see a list of posts in a continuity
So that I can read this glowfic

Scenario: Viewing a flat board
Given there is a board "Test board" with 5 posts
When I view the board "Test board"
Then I should see "Test board"
And I should see 5 posts

Scenario: Viewing a board with various authors
Given there is a board "Author board"
And there is a post "post 1" in "Author board" with 2 authors
And there is a post "post 2" in "Author board" with 5 authors
When I view the board "Author board"
Then I should see 2 posts
And I should see "post 1"
And I should see "and 4 others"
And I should see "post 2"
