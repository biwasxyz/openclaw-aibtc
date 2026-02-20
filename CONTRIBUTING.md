# Contributing

## Running CI Checks Locally

All checks below run in CI on every push and pull request to `main`. Run them locally before pushing.

### ShellCheck (Shell Script Linting)

```bash
shellcheck -S warning local-setup.sh vps-setup.sh update-skill.sh
```

Install: `apt install shellcheck` or `brew install shellcheck`

### Hadolint (Dockerfile Linting)

```bash
hadolint Dockerfile
```

Install: `brew install hadolint` or download from [github.com/hadolint/hadolint](https://github.com/hadolint/hadolint)

### Docker Compose Validation

```bash
docker compose config --quiet
```

Requires a `.env` file (copy from `.env.example` if needed).

### JSON Template Validation

```bash
for f in templates/memory/*.json; do
  python3 -c "import json, sys; json.load(open(sys.argv[1]))" "$f" && echo "OK: $f" || echo "FAIL: $f"
done
```

### Env Var Coverage

Checks that every `${VAR}` in `docker-compose.yml` is defined in `.env.example`:

```bash
# Extract vars from docker-compose.yml
compose_vars=$(grep -oP '\$\{(\w+)' docker-compose.yml | sed 's/\${//' | sort -u)
env_vars=$(grep -oP '^\w+(?==)' .env.example | sort -u)

for var in $compose_vars; do
  echo "$env_vars" | grep -qx "$var" && echo "OK: $var" || echo "MISSING: $var"
done
```

### YAML Frontmatter Validation

Validates `skills/*/SKILL.md` files have valid YAML frontmatter with required `name` and `description` fields. Run the CI script directly:

```bash
python3 -c "
import yaml, glob, sys
for path in sorted(glob.glob('skills/*/SKILL.md')):
    with open(path) as f: content = f.read()
    if not content.startswith('---\n'): print(f'FAIL: {path}'); sys.exit(1)
    end = content.index('\n---', 3)
    data = yaml.safe_load(content[4:end])
    missing = [f for f in ['name','description'] if f not in data]
    print(f'FAIL: {path} missing {missing}' if missing else f'OK: {path}')
    if missing: sys.exit(1)
"
```

### Markdown Lint

```bash
npx markdownlint-cli2 "**/*.md" "#node_modules"
```

Configuration is in `.markdownlint.yml`.

### Integration Tests

```bash
bash tests/test-setup-sync.sh
```

Tests heredoc content sync and autonomy preset values across setup scripts.

## Version Bumping

The `Dockerfile` pins exact versions of `@aibtc/mcp-server` and `mcporter` to ensure
reproducible builds. When a new MCP server version is released, update the pin manually.

### Checking for updates

```bash
# Check current latest version on npm
npm view @aibtc/mcp-server version
npm view mcporter version
```

### Bumping the MCP server version

1. Update the version in `Dockerfile`:

   ```dockerfile
   RUN npm install -g @aibtc/mcp-server@X.Y.Z mcporter@A.B.C \
   ```

2. Rebuild and test:

   ```bash
   docker compose build
   docker compose up -d
   ```

3. Commit with a conventional commit message:

   ```bash
   git commit -m "chore(docker): bump @aibtc/mcp-server to X.Y.Z"
   ```

### What NOT to do

- Do not use `@latest` in the Dockerfile -- this causes non-reproducible builds and
  has previously caused breakage when breaking changes shipped in a new release.
- Do not let `update-skill.sh` manage Dockerfile versions -- that script only updates
  agent skills and configs inside a running container, not the image itself.

---

## Branch Protection Rules

These rules should be configured by a repository admin in **Settings > Branches > Branch protection rules** for the `main` branch.

### Recommended Settings

1. **Require a pull request before merging**
   - Require at least 1 approval
   - Dismiss stale pull request approvals when new commits are pushed

2. **Require status checks to pass before merging**
   - Require branches to be up to date before merging
   - Required status checks:
     - `ShellCheck`
     - `Hadolint Dockerfile Lint`
     - `Docker Compose Config Validation`
     - `JSON Template Validation`
     - `Env Var Coverage Check`
     - `SKILL.md YAML Frontmatter Validation`
     - `Markdown Lint`
     - `Setup Script Integration Tests`

3. **Do not allow bypassing the above settings**
