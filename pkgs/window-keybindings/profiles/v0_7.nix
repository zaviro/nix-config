{
  version = "0.7";

  options.rolePolicies = [
    "contextual"
    "singleton"
  ];

  modifier = "Mod";

  navigation = {
    search.key = "Mod+D";
    recent.key = "Mod+Tab";
  };

  roles = {
    browser = {
      key = "B";
      policy = "contextual";
    };
    terminal = {
      key = "T";
      policy = "contextual";
    };
    editor = {
      key = "E";
      policy = "contextual";
    };
    agent = {
      key = "A";
      policy = "singleton";
    };
    notes = {
      key = "N";
      policy = "singleton";
    };
  };
}
