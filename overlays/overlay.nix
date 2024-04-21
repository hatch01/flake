(unstable: final: prev: {
  unstable = import unstable {
    inherit prev;
  };
  # stay here for example for jetbrains but also other tools
  #jetbrains = prev.jetbrains // {
  #  clion = unstable.jetbrains.clion;
  #};
})
