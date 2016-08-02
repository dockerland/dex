#
# lib.d/display_help.sh for dex -*- shell-script -*-
#

display_help() {
  cat <<-EOF

  A release utility.

  Release branches are orphaned from -master and include the 'common' directory
  with 'application-type' merged in.
    E.g. the result of common/ overlayed with m1/

  Skels track releases using git subtree via the downstreamer. This requires
  non-divergent history in release branches -- e.g. if a project jumps between
  different releases, git-subtree will fail if it cannot find the previous ref.

  As such, the official release branch points to the HEAD of "prerelease" when
  it's deemed stable.

  If a custom branch is specified and gets tracked by a project, you can merge
  this branch into the prerelease branch to avoid divergent history issues
  when downstreaming.

  Usage: release <application-type> [options]

         # create and publish a m1 prerelease  (branch name: prerelease/m1)
         release.sh m1 --publish

         # create a custom prerelease branch (branch name: prerelease/m1-test)
         release.sh m1 --branch prerelease/m1-test

         # stage an official release (branch name: release/m1)
         release.sh m1 --official


  Options:
    --help               Display help

    -b | --branch        Branch name to build or to base official release on
                         (defaults to prerelease/<application-type>)

    -o | --official      Create an official release. First builds a prerelease,
                         then points the official branch to it

    -p | --publish       Automatically push branch(es) to upstream

EOF
}
