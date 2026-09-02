## ADDED Requirements

### Requirement: AI Git Commit Attribution

The system SHALL require every distributed Claude and Codex instruction template to append a stable, machine-readable `Co-Authored-By` trailer when the corresponding AI generates a Git commit message.

#### Scenario: Claude Code generates a commit message

- **GIVEN** Claude Code is operating under any tracked `CLAUDE.md` template from this repository
- **WHEN** Claude Code generates a Git commit message
- **THEN** the template identifies the commit rule as mandatory and states that the trailer MUST NOT be omitted
- **AND** the message ends with `Co-Authored-By: Claude Code <claude-code@anthropic.com>`
- **AND** the trailer is not appended more than once
- **AND** the template does not instruct Claude Code to use the Codex trailer

#### Scenario: Codex generates a commit message

- **GIVEN** Codex is operating under any tracked `AGENTS.md` template from this repository
- **WHEN** Codex generates a Git commit message
- **THEN** the template identifies the commit rule as mandatory and states that the trailer MUST NOT be omitted
- **AND** the message ends with `Co-Authored-By: Codex <codex@openai.com>`
- **AND** the trailer is not appended more than once
- **AND** the template does not instruct Codex to use the Claude Code trailer

#### Scenario: A new instruction template is added

- **GIVEN** a new tracked file named `CLAUDE.md` or `AGENTS.md` is added to the repository
- **WHEN** the attribution coverage test runs
- **THEN** the test fails unless the new template contains exactly one matching AI trailer
- **AND** the test fails if the template contains the other AI's trailer
