Feature: Playback
  Track playback controls in the TUI music player.

  # --- Track selection ---

  Scenario: Play selected track
    Given a library with 2 albums of 3 tracks each
    And I am focused on the track list
    When I press Enter
    Then the first track is playing

  Scenario: Play a different track
    Given a library with 2 albums of 3 tracks each
    And I am focused on the track list
    And I navigate down 2 times
    When I press Enter
    Then track 3 is playing

  # --- Play/pause ---

  Scenario: Toggle pause on playing track
    Given a library with 2 albums of 3 tracks each
    And a track is playing
    When I press Space
    Then playback is paused

  Scenario: Resume paused track
    Given a library with 2 albums of 3 tracks each
    And a track is paused
    When I press Space
    Then playback is resumed

  # --- Track advancement ---

  Scenario: Next track advances to following track
    Given a library with 1 album of 5 tracks
    And I am playing track 1
    When I press n
    Then track 2 is playing
    And the selected track index is 1

  Scenario: Previous track near start goes to prior track
    Given a library with 1 album of 5 tracks
    And track 3 is playing at the beginning
    When I press b
    Then track 2 is playing

  Scenario: Next track at end of album stays on last track
    Given a library with 1 album of 3 tracks
    And the last track is playing
    When I press n
    Then the last track remains playing
