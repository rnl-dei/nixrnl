{ writeText, ... }: writeText "dashy-weaver-conf.yml" (builtins.readFile ./conf.yml)
