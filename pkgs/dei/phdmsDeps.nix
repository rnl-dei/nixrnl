{
  python311,
  fetchPypi,
  uwsgi,
  ...
}:

let
  pth = python311;

  django-q = pth.pkgs.buildPythonPackage rec {
    pname = "django-q";
    version = "1.3.9";
    src = fetchPypi {
      inherit pname version;
      hash = "sha256-XGtNUwqjqr+caqVzdtocoqv4mhVit3A4t6BOUqSgqRs=";
    };
    propagatedBuildInputs = with pth.pkgs; [ setuptools ];
    doCheck = false;
  };
  django-unused-media = pth.pkgs.buildPythonPackage rec {
    pname = "django-unused-media";
    version = "0.2.2";
    src = fetchPypi {
      inherit pname version;
      hash = "sha256-j0a1p9PhDwnjESau+y7+JOPe22qJ2veG9+BVxSmGaO4=";
    };
    doCheck = false;
  };
  django-file-resubmit = pth.pkgs.buildPythonPackage rec {
    pname = "django-file-resubmit";
    version = "0.5.2";
    src = fetchPypi {
      inherit pname version;
      hash = "sha256-9Mnt8nu2lW0GmH5Dds0J+wF13Yzm3GQOWTwJ3dlZAW8=";
    };
    doCheck = false;
  };
  django-crispy-forms = pth.pkgs.buildPythonPackage rec {
    pname = "django-crispy-forms";
    version = "1.14.0";
    src = fetchPypi {
      inherit pname version;
      hash = "sha256-NYh7iFGpMTdN1pcgeo9WxXqcXLnb8Ln6VDFNpWZs6ls=";
    };
    doCheck = false;
  };
  django-phonenumber-field = pth.pkgs.buildPythonPackage rec {
    pname = "django-phonenumber-field";
    version = "6.1.0";
    src = fetchPypi {
      inherit pname version;
      hash = "sha256-sf+VD5CokR/zI8z3fI9v5Cman2cfphyHNKaZQ1nwdEY=";
    };
    build-system = [ pth.pkgs.setuptools-scm ];
    pyproject = true;

    dependencies = [ pth.pkgs.django_3 ];

    doCheck = false;
  };
  pypdftk = pth.pkgs.buildPythonPackage rec {
    pname = "pypdftk";
    version = "0.5";
    src = fetchPypi {
      inherit pname version;
      hash = "sha256-tvfwABM0gIQrO/n4Iiy2vV4rIM9QxewFDy5E2ffcMpY=";
    };
    doCheck = false;
  };
  psycopg2 = pth.pkgs.psycopg2.overrideAttrs (_attrs: rec {
    pname = "psycopg2";
    version = "2.9.3";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-joQdG/NDTamFzF7xPm91yJgc7WAf1wzGvzM1G5FWKYE=";
    };

  });
  uwsgiDEI = uwsgi.override {
    python3 = pth;
    plugins = [ "python3" ];
  };

in
{
  # uwsgi with forced python3 to 3.11 - common to phdms and leic-alumni.
  inherit uwsgiDEI;

  # PHDMS deps.
  inherit
    django-q
    django-unused-media
    django-file-resubmit
    django-crispy-forms
    django-phonenumber-field
    pypdftk
    psycopg2
    ;

  # No custom leic-alumni deps packaged.
}
