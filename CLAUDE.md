## Problem Solving Approach

- After receiving tool results, carefully reflect on their quality and determine optimal next steps before proceeding. Use your thinking to plan and iterate based on this new information, and then take the best next action.

- For maximum efficiency, whenever you need to perform multiple independent operations, invoke all relevant tools simultaneously rather than sequentially.

- If you create any temporary new files, scripts, or helper files for iteration, clean up these files by removing them at the end of the task.

## Code Quality and Implementation

- Always write a high quality, general purpose solution. Implement a solution that works correctly for all valid inputs, not just the test cases. Do not hard-code values or create solutions that only work for specific test inputs. Instead, implement the actual logic that solves the problem generally.

- Focus on understanding the problem requirements and implementing the correct algorithm. Tests are there to verify correctness, not to define the solution. Provide a principled implementation that follows best practices and software design principles.

- If the task is unreasonable or infeasible, or if any of the tests are incorrect, please tell me. The solution should be robust, maintainable, and extendable.

## Frontend Development

- When doing frontend work -
  - Always apply design principles: hierarchy, contrast, balance, and movement
  - Add thoughtful details like hover states, transitions, and micro-interactions
  - Create an impressive demonstration showcasing web development capabilities
  - Include as many relevant features and interactions as possible
  - Don't hold back. Give it your all.

## Development Workflow

- Terminal or bash is the most versatile tool. Use it to scan file contents of huge files, run tests, dev, builds etc. Plan and use terminal to test out code and functionalities when possible and relevant to the task at hand.
- Terminal commands can help quickly explore, manipulate, and analyze code and system resources efficiently.
- Terminal or bash is the most versatile tool. Use it to scan file contents of huge files, run tests,dev, builds etc. Plan and use terminal to test out code and functionalities when possible and relevant to the task at hand.

## Approach to Tasks

- Think carefully and only action the specific task I have given you with the most concise and elegant solution that changes as little code as possible.

# AI Dev Tasks
Use these files when I request structured feature development using PRDs:
~/Documents/Github/fork_exp/ai-dev-tasks/create-prd.md
~/Documents/Github/fork_exp/ai-dev-tasks/generate-tasks.md
~/Documents/Github/fork_exp/ai-dev-tasks/process-task-list.md

## Cave Timer Commands

Cave Timer is a deep work focus tool installed globally at ~/.claude-cave/

- `cave start [minutes]` - Start focus session (default 90 min)
- `cave stop` - End current session
- `cave status` - Check remaining time
- Natural language: "I need to focus for 2 hours", "stop timer", etc.
- while merging a PR always do merge commit, unless rebase is required.
- NEVER add fallbacks/backward-compability/feature flags unless specifically requested by user, we are always building the full new refactored solution.
- if there are uncommited changes and we need to change branches, always default to stashing the changes unless specified by the user.