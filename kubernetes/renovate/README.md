# Renovate — credentials runbook

Renovate runs as a CronJob (`30 22 * * *`, America/New_York) against the
self-hosted GitLab at `gitlab.apps.okd.claffey.cloud`, managing the
`rclaffey/homelab` project.

Both tokens live in Vault at **`secret/homelab/renovate/common`** and are
projected into the `renovate-credentials` Secret by
[`base/external-secret.yaml`](base/external-secret.yaml). Rotation means
updating Vault — External Secrets re-syncs within 1h (`refreshInterval: 1h`).
Never put token values in git.

| Vault property | Env var | Platform | Scope |
| --- | --- | --- | --- |
| `gitlab-token` | `RENOVATE_TOKEN` | self-hosted GitLab | `api`, Developer |
| `github-token` | `GITHUB_COM_TOKEN` | github.com | **no scopes** |

---

## GitLab token — `gitlab-token`

This is the token Renovate uses to do its actual work: scan the repo, push
branches, and open merge requests.

**Create:** GitLab → `rclaffey/homelab` → Settings → Access tokens → Add new token

| Setting | Value |
| --- | --- |
| Type | Project access token (scoped to this one project) |
| Role | **Developer** |
| Scope | **`api`** |
| Expiry | GitLab requires one — record it (see "Expiry" below) |

**Why `api` and not something narrower.** Renovate's GitLab platform requires
the `api` scope for real runs (`read_api` only covers `--dry-run`). Repository
scopes like `write_repository` grant git push but *not* the REST calls Renovate
depends on: creating merge requests, applying `labels`, setting `assignees` and
`reviewers`, and maintaining the Dependency Dashboard issue — all configured in
[`renovate.json`](../../renovate.json). There is no narrower scope that works.

**Why Developer is enough.** Developer permits creating branches, merge
requests, and issues. Maintainer would only be needed if Renovate had to merge
its own MRs into a protected branch — and every `packageRule` in `renovate.json`
sets `automerge: false`, so it never merges. If you enable automerge later, the
token additionally needs "Allowed to merge" on the protected branch, which in
practice means the Maintainer role.

## GitHub token — `github-token`

This token never writes anything and has nothing to do with hosting the repo.
Renovate uses github.com as a *data source*:

- **Changelogs / release notes** rendered into MR bodies for any dependency
  whose source is on GitHub.
- **The `github-releases` datasource** that `renovate.json` uses for Immich
  (added to bypass GHCR tag pagination limits).
- **Rate limits** — unauthenticated GitHub API access is 60 requests/hour,
  which Renovate exhausts quickly and which causes it to flap MRs open and
  closed. An authenticated token raises this to 5,000/hour.

**Create:** GitHub → Settings → Developer settings → Personal access tokens →
Tokens (classic) → Generate new token

| Setting | Value |
| --- | --- |
| Type | Classic PAT |
| Scopes | **none — leave every checkbox unticked** |
| Expiry | your choice; record it |

A classic token with zero scopes still authenticates, which is all that is
needed: it grants read-only access to public data at the higher rate limit.
Do **not** tick `repo` — that would hand out write access to all your private
GitHub repos for a token whose only job is reading public changelogs. If you
prefer a fine-grained token, choose "Public Repositories (read-only)" and add
no account permissions.

(The account can be any GitHub account; it needs no relationship to this repo.)

---

## Expiry — the failure mode to watch

On 2026-08-04 the previous GitLab token expired. Every CronJob run failed with
`FATAL: Initialization error — Authentication failure` and the ArgoCD app went
`Degraded`, but nothing alerted, so it went unnoticed for days. The same
expiry killed ArgoCD's own repo credential.

When you mint either token, put its expiry date in a calendar reminder ~1 week
ahead. To rotate: create the new token, update the property in Vault, and wait
for the ESO refresh (or force it by deleting the `renovate-credentials` Secret —
ESO recreates it immediately).

## Verifying

```bash
# ExternalSecret healthy?
oc get externalsecret renovate-credentials -n renovate

# Which keys landed (never prints values)
oc get secret renovate-credentials -n renovate -o jsonpath='{.data}' | tr ',' '\n' | cut -d'"' -f2

# One-off run without waiting for the schedule
oc create job -n renovate --from=cronjob/renovate renovate-manual-$(date +%s)
oc logs -n renovate -l job-name=renovate-manual-<id> --tail=50
```

A healthy run logs the repository being processed and exits 0. `Authentication
failure` in the first few lines means the GitLab token is wrong, expired, or
lacks the `api` scope.

> Note: the ArgoCD app's health only clears after a **scheduled** run succeeds —
> a manually created Job does not update the CronJob's `lastSuccessfulTime`.
