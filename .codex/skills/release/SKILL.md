---
name: release
description: >-
  Bump VERSION, fold Unreleased changelog entries into that version, tag, and
  publish a GitHub release. Use when the user asks to release, bump the version,
  cut a tag, publish vX.Y.Z or a prerelease (beta/rc), or move the current
  Unreleased changelog into the latest version.
---

# Release

Cut a version from `VERSION` + `make changelog`. Never edit `CHANGELOG.md` by hand.
Do not retag a version that already exists on `origin`.

## When this applies

The user asked to **release**, **bump the version**, **tag**, or **fold Unreleased**
into a version. A release includes commit, tag, push, and `gh release create`.

If they also have unrelated uncommitted work, stop and say so. Do not mix it
into the release commit.

## Version

1. Read `VERSION`.
2. Use the version they named. Strip a leading `v`. Allowed: `1.2.3` or
   `1.2.3-beta` / `1.2.3-beta.1` / `1.2.3-rc.1`.
3. If they said **major** / **minor** / **patch**, bump that segment of the
   current numeric core and drop any prerelease suffix.
4. If they gave no version and no major/minor/patch, ask for one.
5. `make bump` rejects slashes and other unsafe strings. Do not write `VERSION`
   by hand.

## Steps

Run from the repository root. Do not skip hooks.

1. Confirm `git status` is clean (or only files this release will write).
2. Set the version:

   ```sh
   make bump VERSION=1.2.3
   ```

   Use `VERSION=1.2.3-beta` for a prerelease.

3. Commit the bump (and any bump-script/docs that belong to this release):

   ```sh
   git add VERSION
   git commit -m "$(
     cat << 'EOF'
   chore(release): v1.2.3
   
   EOF
   )"
   ```

4. `make changelog`. If `CHANGELOG.md` changed, commit
   `chore(changelog): regenerate from commits`.
5. Point an annotated tag at `HEAD`:

   ```sh
   git tag -a v1.2.3 -m "v1.2.3"
   ```

6. `make changelog` again. This is what folds **Unreleased** into
   `## [1.2.3] - YYYY-MM-DD`. Commit that changelog.
7. If the tag is **not** on `origin`, move the local tag onto the changelog
   commit so the tag’s tree contains the dated section:

   ```sh
   git tag -d v1.2.3
   git tag -a v1.2.3 -m "v1.2.3"
   ```

   If `origin` already has `v1.2.3`, do not delete or force-push it.

8. Push the branch and the tag:

   ```sh
   git push origin HEAD
   git push origin v1.2.3
   ```

9. Publish GitHub. Add `--prerelease` when the version contains `-`:

   ```sh
   gh release create v1.2.3 --title "v1.2.3" --notes "$(
     cat << 'EOF'
   See CHANGELOG.md for commits in this version.
   
   EOF
   )"
   ```

10. Return the release URL.

## Do not

- Edit `CHANGELOG.md` by hand.
- `git commit --amend` or `--force` a tag that is already on `origin`.
- Skip `make changelog` after the tag (Unreleased will not move).
- Retag an older release the user did not name (for example an earlier beta).
