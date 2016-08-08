#
# lib.d/display_help.sh for dex -*- shell-script -*-
#

display_help_image(){
  cat <<-EOF

Piping hot docker executables to your door.

images don't make themselves, dex will.

Usage: dex image <command> [options]

  # build the darwin version of sed from any repository (first found)
  dex build sed:darwin

  # build 'sed' from the "extras" repository
  dex image build extras/sed

  # build all images from the "extras" repository
  dex image build extras/*

Commands:

  build <[repo/]image|*> Builds an image. Optionally slash-pass repository.
  rm <[repo/]image|*>    Remove an image. Optionally slash-pass repository.
  ls                     Lists images dex has built.

Options:

  -h|--help|help        Display help

  -v|--api-version      When building, explicitly pass the API version

  -f|--force            When removing, persisted runs will be deleted.
                        When building, ignore API version check.
EOF
}
