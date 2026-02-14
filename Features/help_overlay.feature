Feature: Help Overlay
  Keyboard shortcut help overlay in the TUI music player.

  Scenario: Show help overlay
    Given a library with 1 album of 3 tracks
    When I press ?
    Then the help overlay is visible

  Scenario: Close help overlay with ?
    Given a library with 1 album of 3 tracks
    And the help overlay is open
    When I press ?
    Then the help overlay is hidden

  Scenario: Close help overlay with Escape
    Given a library with 1 album of 3 tracks
    And the help overlay is open
    When I press Escape
    Then the help overlay is hidden

  Scenario: Help overlay blocks other keys
    Given a library with 1 album of 3 tracks
    And the help overlay is open
    When I press j
    Then the help overlay is visible
    And the selected album index is 0
