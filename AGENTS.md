# Agent and Developer Instructions 

## Platform Support

* Scripts must be written to work cross-platform (Linux and Windows)
* The production environment runs on Linux servers
* Test on both platforms when possible to ensure compatibility

## Code Style and Conventions

### General Guidelines

* Write clear, self-documenting code with meaningful variable and function names
* Follow PowerShell best practices and style guides
* Use consistent indentation (4 spaces for PowerShell)
* Keep functions focused and modular - each function should do one thing well
* Add comment-based help for all public functions using PowerShell's standard format
* Use verbose and debug output streams appropriately
* Write cross-platform compatible code (Linux and Windows)
* Use PowerShell Core cmdlets that work on both platforms
* Avoid Windows-specific cmdlets or APIs unless absolutely necessary
* Use forward slashes or `Join-Path` for file paths to ensure cross-platform compatibility

### PowerShell-Specific Guidelines

* Follow the PowerShell Verb-Noun naming convention for all functions
* Use approved PowerShell verbs (verify with `Get-Verb`)
* Write cmdlets that work well in the pipeline
* Support common parameters (`-Verbose`, `-Debug`, `-ErrorAction`, etc.)
* Use proper PowerShell error handling with try/catch/finally blocks
* Implement proper parameter validation using parameter attributes
* Use `Write-Verbose`, `Write-Debug`, `Write-Warning`, and `Write-Error` appropriately
* Avoid using aliases in scripts and modules (use full cmdlet names)
* Use proper PowerShell formatting: opening braces on the same line, proper indentation

### Naming Conventions

* **Functions**: Use PascalCase with approved Verb-Noun format
* **Variables**: Use PascalCase for script/module-level variables, camelCase for local variables
* **Parameters**: Use PascalCase for all parameter names
* **Constants**: Use PascalCase with descriptive names
* **Module Names**: Use PascalCase with hyphens for readability
* **Script Files**: Use PascalCase with hyphens for readability

### PowerShell Module Structure

* Organize code into proper PowerShell modules with manifests (.psd1)
* Separate public and private functions into different directories
* Use proper module manifest with version, author, and description
* Export only public functions in the module manifest
* Include proper module requirements and dependencies
* Follow the standard PowerShell module folder structure:

```
  Module-Name/
  ├── Module-Name.psd1 (manifest)
  ├── Module-Name.psm1 (root module)
  ├── Public/ (exported functions)
  ├── Private/ (internal functions)
  ├── Classes/ (PowerShell classes if used)
  └── Tests/ (Pester tests)
  ```

### Security Considerations

* Never commit credentials, API keys, or sensitive data to the repository
* Use PowerShell SecureString for handling sensitive data in memory
* Store credentials securely using secret management solutions appropriate for the platform (Linux: secret stores, Windows: Credential Manager, or Azure Key Vault for both)
* Use environment variables or secure configuration files for sensitive settings
* Implement proper authentication and authorization for API calls
* Sanitize user inputs to prevent injection attacks
* Follow the principle of least privilege when requesting permissions
* Use `-NoProfile` when calling PowerShell scripts to avoid unexpected behavior
* Validate and sanitize all external input before processing
* Use `ConvertTo-SecureString` and `ConvertFrom-SecureString` for credential storage
* Secure SFTP credentials and file access on Linux servers

## Testing

### Test Requirements

* Write Pester tests for all functions and modules
* Use Pester 5.x for all testing
* Include unit tests for all public functions
* Include integration tests for API interactions
* Test error handling and edge cases with mock objects
* Ensure tests are deterministic and don't depend on external state
* Use mocking for external API calls in unit tests
* Follow the Arrange-Act-Assert (AAA) pattern in tests
* Name test files with `.Tests.ps1` suffix

### Test Coverage

* Aim for high test coverage, especially for critical sync logic
* Test both success and failure scenarios
* Include tests for parameter validation
* Test pipeline input and output
* Include tests for data validation and transformation
* Use code coverage tools to measure test effectiveness

### Pester Best Practices

* Organize tests using `Describe` and `Context` blocks
* Use `BeforeAll`, `BeforeEach`, `AfterEach`, and `AfterAll` for test setup/teardown
* Mock external dependencies using `Mock` and verify calls with `Should -Invoke`
* Use meaningful test descriptions that explain the scenario being tested
* Test both the happy path and error conditions

## Documentation

### Code Documentation

* Use comment-based help for all public functions with the following sections:

  * `.SYNOPSIS`: Brief description of the function
  * `.DESCRIPTION`: Detailed description of what the function does
  * `.PARAMETER`: Document each parameter
  * `.EXAMPLE`: Provide at least one usage example
  * `.INPUTS`: Describe what can be piped to the function
  * `.OUTPUTS`: Describe what the function returns
  * `.NOTES`: Additional information (author, version, etc.)
  * `.LINK`: Related links or documentation
* Place comment-based help at the beginning of each function
* Document module manifests with proper metadata
* Keep README.md up to date with setup and usage instructions
* Document environment variables and configuration options
* Include examples of common usage scenarios

### Commit Messages

* Use conventional commit format (feat:, fix:, docs:, etc.)
* Write clear, descriptive commit messages
* Reference issue numbers when applicable

### CSV File Processing

* Parse Final Site Enrollment CSV files with proper encoding detection
* Handle various CSV formats and edge cases (quotes, commas in fields, line endings)
* Use `Import-Csv` cmdlet for standard CSV processing
* Validate CSV structure and required fields before processing
* Log all parsing errors with sufficient detail
* Support large CSV files efficiently using streaming when possible

### Error Handling

* Use PowerShell's error handling mechanisms (`try/catch/finally`)
* Set `$ErrorActionPreference` appropriately at the script/function level
* Use `-ErrorAction` parameter to control error behavior
* Throw terminating errors for critical failures using `throw`
* Write non-terminating errors using `Write-Error` with appropriate error records
* Provide meaningful error messages with context
* Log errors with sufficient context for debugging using `Write-Error` or custom logging
* Implement proper cleanup in `finally` blocks
* Gracefully handle API unavailability with retry logic
* Use `$PSCmdlet.ThrowTerminatingError()` for proper error records in advanced functions

## Performance

### Optimization Guidelines

* Optimize for both speed and reliability
* Use PowerShell pipelines efficiently - avoid unnecessary array creation
* Use `foreach` method instead of `ForEach-Object` for large collections when pipeline isn't needed
* Filter early in the pipeline to reduce data processing
* Use `System.Collections.Generic.List` instead of `+=` for building large arrays
* Implement efficient data structures appropriate for the task
* Monitor memory usage for large data sets
* Use PowerShell's parallel processing features (`ForEach-Object -Parallel` in PowerShell 7+) for I/O-bound tasks
* Be cautious about race conditions when using parallel processing
* In data synchronization, maintain order of operations when necessary to prevent data inconsistencies
* Use runspaces or jobs for true parallel processing when needed
* Avoid unnecessary object creation and variable assignments
* Use `.Where()` and `.ForEach()` methods for better performance on large collections

## Dependencies

* Use PowerShell Gallery modules when available
* Specify required PowerShell version (7.0 or higher) in module manifests
* Document all module dependencies in the manifest using `RequiredModules`
* Keep dependencies up to date and review security advisories regularly
* Minimize external dependencies when possible
* Test compatibility across PowerShell 7.x versions on both Linux and Windows
* Prefer cross-platform compatible modules from PowerShell Gallery
* Avoid Windows-specific modules unless absolutely necessary
* Document any platform-specific requirements or limitations in README.md
* Use `#Requires` statements in scripts to enforce version and module requirements

## Development Workflow

* Create feature branches for new work
* Use descriptive branch names (e.g., `feature/sync-student-data`, `fix/api-timeout`)
* Keep pull requests focused and reviewable
* Run Pester tests before committing using `Invoke-Pester`
* Use PSScriptAnalyzer to lint PowerShell code before committing
* Test on both Linux and Windows platforms when possible
* Use the provided Postman collection for API testing and development
* Reference sample Final Site Enrollment CSV files for testing CSV parsing logic
* Update documentation alongside code changes
* Follow semantic versioning for module releases
* Update module manifest version numbers appropriately