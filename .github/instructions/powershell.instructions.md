---
applyTo: '**/*.ps1,**/*.psm1'
description: 'PowerShell cmdlet and scripting best practices based on Microsoft guidelines'
---

# PowerShell Development Guidelines

This guide defines PowerShell specific standards for this repository. Follow Microsoft PowerShell cmdlet design principles and produce safe, maintainable, automation friendly code.

## 1. Naming Conventions

### 1.1 Verb Noun Format
1. Use approved PowerShell verbs from Get Verb.
2. Use singular nouns.
3. Use PascalCase for verb and noun.
4. Do not use special characters or spaces.

### 1.2 Parameter Names
1. Use PascalCase.
2. Use descriptive, unambiguous names.
3. Use singular form unless always multiple.
4. Follow standard PowerShell parameter naming patterns.

### 1.3 Variable Names
1. Use PascalCase for public variables.
2. Use camelCase for private or local variables.
3. Avoid abbreviations.
4. Use meaningful names.

### 1.4 Alias Avoidance
1. Use full cmdlet names.
2. Do not use aliases in scripts.
3. Use full parameter names.
4. Custom aliases must be documented.

## 2. Parameter Design

### 2.1 Standard Parameters
1. Use common names such as Path, Name, Force.
2. Follow built in cmdlet conventions.
3. Use aliases only when appropriate and documented.

### 2.2 Type Selection
1. Prefer common .NET types.
2. Use validation attributes where appropriate.
3. Use ValidateSet for constrained values.
4. Enable tab completion through proper typing.

### 2.3 Switch Parameters
1. Use switch for boolean flags.
2. Avoid true false parameters.
3. Default to false when omitted.
4. Use action oriented names.

## 3. Pipeline and Output

### 3.1 Pipeline Input
1. Use ValueFromPipeline where direct object input is appropriate.
2. Use ValueFromPipelineByPropertyName where property mapping is appropriate.
3. Implement Begin, Process, and End blocks for streaming functions.
4. Document pipeline behavior.

### 3.2 Output Objects
1. Return structured objects, not formatted text.
2. Use PSCustomObject for structured data.
3. Do not use Write Host for data output.
4. Enable downstream processing.

### 3.3 PassThru Pattern
1. Action cmdlets should not output by default.
2. Implement PassThru when returning modified objects is useful.
3. Use Verbose or Warning streams for operational messages.

## 4. Error Handling and Safety

### 4.1 ShouldProcess
1. Use CmdletBinding with SupportsShouldProcess for system changes.
2. Set appropriate ConfirmImpact.
3. Call ShouldProcess before performing destructive actions.
4. Use ShouldContinue only for additional confirmation scenarios.

### 4.2 Message Streams
1. Use Write Verbose for operational detail.
2. Use Write Warning for non fatal issues.
3. Use Write Error for non terminating errors.
4. Use ThrowTerminatingError in advanced functions.
5. In scripts, use throw with a clear message.
6. Do not use Write Host except for interactive UI only.

### 4.3 Error Handling Pattern
1. Use try catch blocks where appropriate.
2. Set ErrorActionPreference deliberately.
3. Distinguish terminating and non terminating errors.
4. Prefer PS Cmdlet WriteError and ThrowTerminatingError in advanced functions.
5. Construct proper ErrorRecord objects when needed.

### 4.4 Non Interactive Design
1. Accept input via parameters.
2. Do not use Read Host in automation scripts.
3. Support unattended automation.
4. Document required inputs clearly.

## 5. Documentation and Style

### 5.1 Comment Based Help
1. All public functions must include comment based help.
2. Include Synopsis, Description, Parameter, Example, Outputs, and Notes sections.
3. Provide realistic usage examples.

### 5.2 Formatting
1. Use consistent indentation with four spaces.
2. Place opening braces on the same line.
3. Place closing braces on a new line.
4. Use line breaks after pipeline operators.
5. Use consistent spacing.
6. Avoid unnecessary whitespace.

### 5.3 Pipeline Support
1. Implement Begin, Process, End when appropriate.
2. Support pipeline by property name when logical.
3. Return proper objects.

### 5.4 Avoid Aliases
1. Use full cmdlet names in repository code.
2. Do not use shorthand operators for readability in committed code.