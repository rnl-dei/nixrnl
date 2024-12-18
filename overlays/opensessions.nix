{ inputs, ... }:
_final: prev: {
  fping = inputs.opensessions.packages."${prev.system}".fping;
  opensessions = inputs.opensessions.packages."${prev.system}".default;
}
