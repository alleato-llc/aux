Feature: Volume Control
  As a user
  I want to adjust the playback volume with keyboard shortcuts
  So that I can control how loud the music plays

  # --- Volume adjustment ---

  Scenario: Increase volume from default stays at maximum
    Given a library with 1 album of 3 tracks each
    When I press +
    Then the volume is 100

  Scenario: Decrease volume from default
    Given a library with 1 album of 3 tracks each
    When I press -
    Then the volume is 95

  Scenario: Decrease volume multiple times
    Given a library with 1 album of 3 tracks each
    When I press -
    And I press -
    And I press -
    Then the volume is 85

  Scenario: Volume floor at zero
    Given a library with 1 album of 3 tracks each
    And the volume is set to 0
    When I press -
    Then the volume is 0
