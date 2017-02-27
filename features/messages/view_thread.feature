Feature: Write New Post
As a user
I want to be able to view messages
So that I can communicate with other users

Scenario: View thread
Given I am logged in
And I have a message thread
When I go to my inbox
And I open the message
Then I should see 3 messages

Scenario: View long message
Given I am logged in
And I have a long message
When I go to my outbox
And I open the message
Then I should see the shortened message
