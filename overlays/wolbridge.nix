{ inputs, ... }: _final: prev: { wolbridge = inputs.wolbridge.packages."${prev.system}".default; }
