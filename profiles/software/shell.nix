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

    # Python
    (python3.withPackages (ps:
      with ps; [
        # General
        pip
        requests
        virtualenv

        # CD
        imbalanced-learn
        ipython
        jupyter
        matplotlib
        # mlxtend # TODO broken, re-enable on 23.05
        numpy
        pandas
        pip
        seaborn
        scipy
        scikit-learn
        statsmodels
        torch-bin

        # FP (LEFT)
        (buildPythonPackage rec {
          pname = "bnf";
          version = "1.0.4";
          src = fetchPypi {
            inherit pname version;
            sha256 = "sha256-EV2STk7/5jVdivdeup+Lg/9zCi0USkUUd8edc0xaT7Q=";
          };
          doCheck = false;
          propagatedBuildInputs = [
            # Specify dependencies
            pkgs.python3Packages.ply
          ];
        })
        pylint
        lizard

        # PRI
        nltk
        whoosh
        (buildPythonPackage rec {
          pname = "concepts";
          version = "0.9.2";
          src = fetchPypi {
            inherit pname version;
            sha256 = "sha256-i7+p/9+JzG4Tx5qQJHQIZ5dQCzHQQ2BKodY7/l+q2iw=";
            extension = "zip";
          };
          doCheck = false;
          propagatedBuildInputs = [
            # Specify dependencies
            (buildPythonPackage rec {
              pname = "bitsets";
              version = "0.8.4";
              src = fetchPypi {
                inherit pname version;
                sha256 = "sha256-MT7FgH9uoqld7F/b9dEimjT21J8IFYSuS+S8J59YMc0=";
                extension = "zip";
              };
              doCheck = false;
            })
            pkgs.python3Packages.graphviz
            pkgs.graphviz
          ];
        })
        keras
        (buildPythonPackage rec {
          pname = "keras-bert";
          version = "0.89.0";
          src = fetchPypi {
            inherit pname version;
            sha256 = "sha256-01RXyREw4j/JqXGBsOtce4HWlFtA7cUjEPb3E+1Ors0=";
          };
          doCheck = false;
          propagatedBuildInputs = [
            # Specify dependencies
            pkgs.python3Packages.numpy
            (buildPythonPackage rec {
              pname = "keras-transformer";
              version = "0.40.0";
              src = fetchPypi {
                inherit pname version;
                sha256 = "sha256-t/n4qX4HzBkK23YVnQ3Mx9xzJqxxTilNEF3dv1tYwwQ=";
              };
              doCheck = false;
              propagatedBuildInputs = [
                # Specify dependencies
                (buildPythonPackage rec {
                  pname = "keras-layer-normalization";
                  version = "0.16.0";
                  src = fetchPypi {
                    inherit pname version;
                    sha256 = "sha256-gNCpq1TDUXlIa5n2lAyWuWynuOh7IEUBu2vKfdghYAE=";
                  };
                  doCheck = false;
                  propagatedBuildInputs = [
                    # Specify dependencies
                    pkgs.python3Packages.numpy
                  ];
                })
                (buildPythonPackage rec {
                  pname = "keras-position-wise-feed-forward";
                  version = "0.8.0";
                  src = fetchPypi {
                    inherit pname version;
                    sha256 = "sha256-mHCAFz3V9KJ4GeDRBZjgHuLxlzsUNQh3MEWTE0jEcKI=";
                  };
                  doCheck = false;
                  propagatedBuildInputs = [
                    # Specify dependencies
                    pkgs.python3Packages.numpy
                  ];
                })
                (buildPythonPackage rec {
                  pname = "keras-pos-embd";
                  version = "0.13.0";
                  src = fetchPypi {
                    inherit pname version;
                    sha256 = "sha256-CbD690fn7HGUCiiIscruYGQe03zCR7bVc9l5+J1C7yA=";
                  };
                  doCheck = false;
                  propagatedBuildInputs = [
                    # Specify dependencies
                    pkgs.python3Packages.numpy
                  ];
                })
                (buildPythonPackage rec {
                  pname = "keras-multi-head";
                  version = "0.29.0";
                  src = fetchPypi {
                    inherit pname version;
                    sha256 = "sha256-sGNO7St31rNAl6LX7EnQgNd4gTIY3WE3T9d24hdiu/A=";
                  };
                  doCheck = false;
                  propagatedBuildInputs = [
                    # Specify dependencies
                    (buildPythonPackage rec {
                      pname = "keras-self-attention";
                      version = "0.51.0";
                      src = fetchPypi {
                        inherit pname version;
                        sha256 = "sha256-d/znKxLSNXIsu899pbNgm4nuIS9fBzUpRcwIjoUJAOk=";
                      };
                      doCheck = false;
                      propagatedBuildInputs = [
                        # Specify dependencies
                        pkgs.python3Packages.numpy
                      ];
                    })
                  ];
                })
                (buildPythonPackage rec {
                  pname = "keras-embed-sim";
                  version = "0.10.0";
                  src = fetchPypi {
                    inherit pname version;
                    sha256 = "sha256-FkpZEWjHV9GCEqG9SYPtAVqbwtFI4YeLzQHCunEsN1s=";
                  };
                  doCheck = false;
                  propagatedBuildInputs = [
                    # Specify dependencies
                    pkgs.python3Packages.numpy
                  ];
                })
              ];
            })
          ];
        })
      ]))
  ];

  # The following two lines are needed for the C++ headers to be found outside a
  # nix-shell with this package.
  # https://discourse.nixos.org/t/c-header-includes-in-nixos/17410/2
  environment.extraOutputsToInstall = ["flex"];
  environment.variables.C_INCLUDE_PATH = "${pkgs.flex}/include:${pkgs.papi}/include";
  environment.variables.CPLUS_INCLUDE_PATH = "${pkgs.flex}/include";
}
