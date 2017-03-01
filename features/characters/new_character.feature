Feature: Create New Character
As a author
I want to be able to create characters
So that I can tag posts with them

Scenario: Logged in can load form
Given I am logged in
And I have 2 galleryless icons
When I go to create a new character
Then I should see "New Character"
