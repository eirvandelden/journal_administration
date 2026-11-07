# Gives a view test the `menu` helper that controllers provide, with a map that holds no hubs.
module ViewMenu
  #: () -> Appkit::Menu
  def menu
    @menu ||= Appkit::Menu.new(hubs: [], account: [], controller_path: "accounts", params: {})
  end
end
