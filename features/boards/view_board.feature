Feature: View Board
As a reader
I want to be able to see a list of posts in a continuity
So that I can read this glowfic

Scenario: Viewing a flat board
Given there is a board "Test board" with 5 posts
When I view the board "Test board"
Then I should see "Test board"
And I should see 5 posts
