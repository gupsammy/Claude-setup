setup a few git worktrees in '.trees' folder depends on number of parallel agents needed, so we can have different sandbox environment for experimentation
Run `git worktree add .trees/<branch-name>`
Replace branch-with a good name that reflect the meaning
After that, for each branch, we should go into the folder (with absolute path) and do dependency installation to setup. Always first determine the package manager, virtual environment availability details.