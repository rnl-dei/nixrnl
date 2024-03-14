{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Version Control
    git

    # Editor
    emacs
    nano
    neovim
    vim

    # Compiler
    gcc
    clang
    bison
    byacc
    flex
    nasm
    yasm

    # Debugger
    gdb
    valgrind

    # Build Tool
    gnumake
    cmake

    # Language
    jdk17
    unstable.swiProlog
    julia
    rustc
    cargo
    sbcl
    nodejs

    # Misc
    atool
    bc
    curl
    ffmpeg
    file
    libqalculate
    lsof
    mysql
    nmap
    postgresql
    unzip
    wget
    zip

    # C/C++
    boost
    clang
    gcc
    gdb
    valgrind

    # Java
    gradle
    maven

    (python3.withPackages (ps:
      with ps; [
        # General
        requests
        virtualenv
      ]))
    conda
  ];

  # The following two lines are needed for the C++ headers to be found outside a
  # nix-shell with this package.
  # https://discourse.nixos.org/t/c-header-includes-in-nixos/17410/2
  environment.extraOutputsToInstall = ["flex"];
  environment.variables.C_INCLUDE_PATH = "${pkgs.flex}/include:${pkgs.papi}/include";
  environment.variables.CPLUS_INCLUDE_PATH = "${pkgs.flex}/include";
}
