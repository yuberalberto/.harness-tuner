---
name: zoom-out
description: >
  Step back and give broader context or a higher-level perspective. Use when
  unfamiliar with a section of code or need to understand how it fits into the
  bigger picture. Maps all relevant modules and callers using domain glossary.
allowed-tools: Read Glob Grep Bash
effort: medium
---

# Zoom Out

Go up a layer of abstraction. Map all the relevant modules and callers, using
the project's domain glossary vocabulary.

## Process

1. **Identify the scope**

   Determine what area of code needs mapping:
   - A specific module or package
   - A domain concept (Order, Payment, Inventory, etc.)
   - A cross-cutting concern (auth, logging, etc.)
   - The entire system architecture

2. **Explore the codebase**

   Map the relationships:
   - Who calls this module?
   - What does this module call?
   - Where is the data flowing?
   - What are the key decision points or branching paths?

3. **Use domain language**

   - Read `CONTEXT.md` to understand the domain vocabulary
   - Refer to concepts by their business names, not implementation names
   - Example: talk about "Order intake" not "OrderHandler", "Fulfillment" not
     "ShipmentService"

4. **Create a map**

   Draw ASCII diagrams or describe in prose:

   ```
   ┌─────────────────┐
   │   HTTP Handler  │
   └────────┬────────┘
            │
            ↓
   ┌─────────────────┐
   │  Order Service  │  ← Core business logic
   └────────┬────────┘
            │
      ┌─────┴─────┐
      ↓           ↓
   Payment     Inventory
   Gateway     Service
   ```

5. **Point out key insights**

   - Which parts are stable vs. actively changing?
   - Where is the complexity concentrated?
   - What are the major dependencies?
   - How does this fit into the larger system?

6. **Stop here**

   This is a mapping exercise, not a design review. Once the picture is clear,
   suggest the next step (exploration, design, refactoring, testing, etc.).
