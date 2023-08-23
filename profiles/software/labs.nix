{pkgs, ...}: {
  imports = [./shell.nix];

  environment.systemPackages = with pkgs; [
    # Browser
    firefox
    chromium

    # Misc
    gimp
    libreoffice-fresh
    mysql-workbench
    pgadmin4
    redshift
    vlc

    # IDE
    vscode.fhs
    jetbrains.idea-community
    jetbrains.pycharm-community

    # CMU
    android-studio

    # CNV
    awscli2
    jdk11
    jq
    pin

    # CPD
    intel-oneapi-vtune
    mpi

    # Comp
    bison
    byacc
    flex
    nasm
    yasm

    # ES
    cypress
    jetbrains.idea-community

    # FP
    jetbrains.pycharm-community

    # LN
    graphviz
    openfst

    # LP
    unstable.swiPrologWithGui

    # OC
    papi

    # PAva
    julia
    sbcl

    # SD
    eclipses.eclipse-java
    jetbrains.idea-community
    maven

    # QS
    dafny

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
        # mlxtend # TODO: Package marked as broken (23.05)
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
}
