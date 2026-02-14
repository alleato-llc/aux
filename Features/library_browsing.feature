Feature: Library Browsing
  Navigate albums and tracks in the TUI music player.

  # --- Album navigation ---

  Scenario: Navigate down in sidebar
    Given a library with 3 albums of 3 tracks each
    And I am focused on the sidebar
    When I press j
    Then the selected album index is 1

  Scenario: Navigate up in sidebar
    Given a library with 3 albums of 3 tracks each
    And I am focused on the sidebar
    And I navigate down 2 times
    When I press k
    Then the selected album index is 1

  Scenario: Cannot navigate above first album
    Given a library with 3 albums of 3 tracks each
    And I am focused on the sidebar
    When I press k
    Then the selected album index is 0

  Scenario: Cannot navigate below last album
    Given a library with 3 albums of 3 tracks each
    And I am focused on the sidebar
    And I navigate down 5 times
    When I press j
    Then the selected album index is 2

  # --- Track navigation ---

  Scenario: Navigate down in track list
    Given a library with 1 album of 5 tracks
    And I am focused on the track list
    When I press j
    Then the selected track index is 1

  Scenario: Navigate up in track list
    Given a library with 1 album of 5 tracks
    And I am focused on the track list
    And I navigate down 3 times
    When I press k
    Then the selected track index is 2

  Scenario: Cannot navigate above first track
    Given a library with 1 album of 5 tracks
    And I am focused on the track list
    When I press k
    Then the selected track index is 0

  Scenario: Cannot navigate below last track
    Given a library with 1 album of 5 tracks
    And I am focused on the track list
    And I navigate down 10 times
    When I press j
    Then the selected track index is 4

  # --- Focus switching ---

  Scenario: Switch focus to track list with l
    Given a library with 2 albums of 3 tracks each
    And I am focused on the sidebar
    When I press l
    Then focus is on the track list

  Scenario: Switch focus to sidebar with h
    Given a library with 2 albums of 3 tracks each
    And I am focused on the track list
    When I press h
    Then focus is on the sidebar

  Scenario: Toggle focus with Tab from sidebar
    Given a library with 2 albums of 3 tracks each
    And I am focused on the sidebar
    When I press Tab
    Then focus is on the track list

  Scenario: Toggle focus with Tab from track list
    Given a library with 2 albums of 3 tracks each
    And I am focused on the track list
    When I press Tab
    Then focus is on the sidebar

  Scenario: Enter from sidebar focuses track list
    Given a library with 2 albums of 3 tracks each
    And I am focused on the sidebar
    When I press Enter
    Then focus is on the track list

  # --- Album selection resets track index ---

  Scenario: Selecting a new album resets track selection
    Given a library with 2 albums of 3 tracks each
    And I am focused on the track list
    And I navigate down 2 times
    When I press h
    And I press j
    Then the selected track index is 0
