Feature: Visualizer
  Visualizer mode switching in the TUI music player.

  Scenario: Default visualizer is spectrum
    Given a library with 1 album of 3 tracks
    Then the visualizer mode is spectrum

  Scenario: Cycle visualizer to oscilloscope
    Given a library with 1 album of 3 tracks
    When I press v
    Then the visualizer mode is oscilloscope

  Scenario: Cycle visualizer back to spectrum
    Given a library with 1 album of 3 tracks
    And the visualizer is set to oscilloscope
    When I press v
    Then the visualizer mode is spectrum
