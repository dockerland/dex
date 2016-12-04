display_help_image(){
  cat <<-EOF

dex - run applications without installing them or their dependencies.

About image:
  The image command is a plumbing command to build and maintain images. It's
  used by the dex 'run' and 'install' commands.

Usage:
  dex image [options...] <command>

Options:
  -h|--help
    Displays help

Commands:
  build [-p|--pull] <[repository]/image[:tag]...>
    Build image(s) from source repositories. Use [repository]/ prefix to specify
    a repository. If no repository is specified, dex builds first match found.

    Build all images in a repository by leaving off image name.

    Examles:
      dex image build sed:macos ansible edit
      dex image build extra/sed

      # build all images in the "extra" repository (following are equivalent)
      dex image build extra/

  inspect <[repository]/image[:tag]>
    Inspect the specified image

    Examples:
      dex inspect sed:macos
      dex inspect extra/ansible

  ls [-q|--quiet] [[repository]/image[:tag]...]
    List built image(s). Use [repository]/ prefix to specify a repository.
    --quiet limits output to name only.

    Examples:
      dex image ls -q
      dex image ls extra/

  rm <[repository]/image[:tag]...>
    Removes built image(s). Use [repository]/ prefix to specify a repository.
    Remove all images built from a repository by leaving off image name.

    Examples:
      dex image rm sed:macos ansible edit

      # removes all images built from the "extra" repository
      dex image rm extra/

EOF
}
