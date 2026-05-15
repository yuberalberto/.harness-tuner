---
description: Generate comprehensive context documents for existing codebases
---

# Context Doc — Codebase Context Generation

This workflow generates comprehensive context documents for existing codebases.

## Trigger

Invoke this workflow when documenting an existing codebase, onboarding new team members, or preparing for modernization. Usage: `/context-doc [directory or module to document]`

## Steps

### Step 1: Codebase Survey

- Identify languages, frameworks, and build tools
- Map the directory structure and its organization pattern
- Count files, lines of code, test coverage
- Identify configuration files and what they control
- **Output**: Technology stack and structure overview

### Step 2: Architecture Extraction

- Identify entry points (main files, API routers, CLI handlers)
- Map the layer structure (presentation → business → data)
- Identify core patterns used (MVC, DDD, CQRS, etc.)
- Document data flow through the system
- **Output**: Architecture description with component diagram

### Step 3: Data Model Documentation

- Extract all data models/entities
- Document fields, types, relationships
- Identify the source of truth for each entity
- Map how data transforms as it moves through layers
- **Output**: Data model inventory

### Step 4: API and Interface Inventory

- List all external APIs (REST, GraphQL, gRPC, WebSocket)
- List all internal interfaces between modules
- Document request/response formats
- Identify authentication/authorization mechanisms
- **Output**: Interface catalog

### Step 5: Business Logic Map

- Identify the core business rules
- Document decision points and their conditions
- Map state machines and transitions
- Identify validation rules and where they're enforced
- **Output**: Business logic documentation

### Step 6: Pattern Recognition

- Identify recurring patterns (repositories, services, factories)
- Document conventions (naming, file organization, error handling)
- Note anti-patterns or tech debt
- Identify areas of high complexity
- **Output**: Patterns and conventions guide

### Step 7: Compile Context Document

Assemble all findings into a single context document:
- Project overview and purpose
- Technology stack
- Architecture with diagrams
- Key data models
- API inventory
- Business logic summary
- Conventions and patterns
- Known issues and tech debt

- **Output**: Complete context document (PROJECT_CONTEXT.md or similar)

## Output

At completion:
- Comprehensive context document covering all aspects of the codebase
- Suitable for onboarding, modernization planning, or team reference
