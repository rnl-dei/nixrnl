{
  lib,
  stdenv,
  fetchFromGitHub,
  python3Packages,
  gitUpdater,
  system ? builtins.currentSystem,
  ...
}:

let
  # Explicitly define unstable here, can't be overridden
  unstable =
    import
      (fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
        sha256 = "sha256:0aics7ak6d6gd2fz12yq7hgs2gs8izlpmf6imhbr9amywgk1l72g";
        # You can add a hash for reproducibility
      })
      {
        inherit system;
        config.allowUnfree = true;
      };
  myTinygrad = unstable.python3Packages.tinygrad.override {
    cudaSupport = true;

  };
in

unstable.python3Packages.buildPythonApplication rec {
  pname = "exo";
  version = "0.0.15-alpha";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "exo-explore";
    repo = "exo";
    tag = "v${version}";
    hash = "sha256-GoYfpr6oFpreWQtSomOwgfzSoBAbjqGZ1mcc0u9TBl4=";
  };

  build-system = with unstable.python3Packages; [ setuptools ];

  pythonRelaxDeps = true;

  pythonRemoveDeps = [ "uuid" ];

  dependencies = with unstable.python3Packages; [
    tensorflow
    aiohttp
    aiohttp-cors
    aiofiles
    grpcio
    grpcio-tools
    jinja2
    numpy
    nuitka
    nvidia-ml-py
    opencv-python
    pillow
    prometheus-client
    protobuf
    psutil
    pydantic
    requests
    rich
    scapy
    tqdm
    transformers
    myTinygrad
    uvloop
  ];

  pythonImportsCheck = [
    "exo"
    "exo.inference.tinygrad.models"
  ];

  nativeCheckInputs = with unstable.python3Packages; [
    mlx
    pytestCheckHook
  ];

  disabledTestPaths = [
    "test/test_tokenizers.py"
  ];

  # Tests require `mlx` which is not supported on linux.
  doCheck = stdenv.hostPlatform.isDarwin;

  passthru = {
    updateScript = gitUpdater {
      rev-prefix = "v-";
    };
  };

  meta = {
    description = "Run your own AI cluster at home with everyday devices";
    homepage = "https://github.com/exo-explore/exo";
    changelog = "https://github.com/exo-explore/exo/releases/tag/v${version}";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ GaetanLepage ];
    mainProgram = "exo";
  };
}
