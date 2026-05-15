# Git Flow

Commit changes with conventional format, push to remote, and optionally create a pull request with a standardized template. Specify a commit message hint after the command, or let Cascade generate one from the diff.

## Steps

1. **Check repository status**
   - Run `git status` and `git branch --show-current`.
   - If no changes exist, inform the user and stop.
   - If the user specified "push" only, skip to step 6.

2. **Analyze changes**
   - Run `git diff` and `git diff --cached` to understand what changed.

3. **Context is managed by Engram**
   - Project context, decisions, and learnings are automatically persisted through Engram.
   - mem_save and mem_session_summary handle this automatically.
   - Proceed to staging files.

4. **Stage files**
   Ask the user which files to stage:
   - All: `git add .`
   - Specific: `git add [file-paths]`

5. **Generate commit message**
   Based on the diff, propose a message with format: `[type]: [description]`

   **Types:** feat, fix, docs, style, refactor, test, chore, perf

   **Rules:**
   - Imperative mood ("add" not "added")
   - First line under 72 characters
   - Be specific

   Present the message and wait for user approval before committing.

6. **Create commit**
   ```
   git commit -m "[approved-message]"
   ```

7. **Push to remote?**
   Ask the user. If yes:
   ```
   git push --set-upstream origin [branch-name]
   ```
   If no, stop here.

8. **Create Pull Request?**
   Ask the user. If yes, create a PR using the available tool (gh CLI or IDE integration) with this body template:

   ```
   ## Changes
   [Summary from commits]

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation

   ## Testing
   - [ ] Tested locally
   - [ ] Added tests

   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Self-review completed
   - [ ] Documentation updated
   ```

   If no, stop here.

9. **Summary**
   Display:
   - Commit hash
   - Branch name
   - PR URL (if created)
   - CONTEXT.md updated: yes / skipped (if repo had no CONTEXT.md)
