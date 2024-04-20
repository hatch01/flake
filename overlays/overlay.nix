(unstable: final: prev: {
  unstable = unstable;
  ollama = unstable.ollama;
  jetbrains = prev.jetbrains // {
    clion = unstable.jetbrains.clion;
  };
})
