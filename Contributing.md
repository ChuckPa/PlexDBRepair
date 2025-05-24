
## How to contribute

As this tool becomes more popular, it also becomes more important to coordinate and document our work.

To contribute to the project,  please follow the following instructions:

### Open an Issue describing the problem or enhancement.
  - Add a label to the issue

### When submitting your work for review and merge:

1. Create an issue in the DBRepair repo against the current release
   - Describe the deficiency to be addressed in sufficient detail

2. Complete your work in your branch
   - Be certain to REBASE prior to starting work.

3. Prior to opening a pull request,
   - Squash multiple commits into a single commit.
   - Clean up the commit message after squashing.
   - Use force-push if needed to unify all changes so there is one hash to reference.

4. Open the pull request against the master branch

5. In the pull request, provide a description of what change(s) where made
   - As last text added, on a blank line,
   - Add the text:   `Fixes:`  followed by the URL of the open Issue
     eg:   Fixes:   https://github.com/ChuckPa/DBRepair/issues/12    (if we were fixing issue 12)

   - Adding the above text & URL has the following impact:
   -- The Issue which prompted the change is forever linked to the PR making documentation easy.
   -- In the event of unforseen issues,  reverting the changes will be trivial and allow easier rework.

6. Be certain to request review with your pull request.

7. Upon completion of review and testing, contributions will be merged into master.
   When the PR is approved and merged,  Github will automatically mark the issue as closed and fixed.

8. The fix will be included in the next release or immediately in a new release if so warranted.


### Policy

While questions, suggestions, enhancement requests, and bug fixes are welcome and almost always implemented,
it's not possible to accept PRs without an accompanying issue documention which justifies the change.

Thanks,
Chuck
