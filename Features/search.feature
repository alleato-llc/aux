Feature: Search
  Album search and filtering in the TUI music player.

  # --- Enter/exit search mode ---

  Scenario: Enter search mode
    Given a library with 3 albums of 3 tracks each
    When I press /
    Then search mode is active
    And the search query is empty

  Scenario: Exit search with Escape clears query
    Given a library with 3 albums of 3 tracks each
    And I am in search mode with query "test"
    When I press Escape
    Then search mode is inactive
    And the search query is empty

  Scenario: Commit search with Enter keeps filter
    Given a library with 3 albums of 3 tracks each
    And I am in search mode with query "Artist 1"
    When I press Enter
    Then search mode is inactive
    And the search query is "Artist 1"

  # --- Typing in search ---

  Scenario: Type characters into search
    Given a library with 3 albums of 3 tracks each
    And I am in search mode
    When I type "rock"
    Then the search query is "rock"

  Scenario: Backspace removes last character
    Given a library with 3 albums of 3 tracks each
    And I am in search mode with query "rock"
    When I press Backspace
    Then the search query is "roc"

  # --- Filtering ---

  Scenario: Search filters albums by name
    Given a library with 3 albums of 3 tracks each
    And I am in search mode
    When I type "Album 1"
    Then 1 album is visible

  # --- Clear filter ---

  Scenario: Clear filter restores all albums
    Given a library with 3 albums of 3 tracks each
    And I am in search mode with query "Album 1"
    And I press Enter
    When I press c
    Then 3 albums are visible
