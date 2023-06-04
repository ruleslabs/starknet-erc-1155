#[account_contract]
mod Account {
  #[constructor]
  fn constructor() {}

  #[view]
  fn supports_interface(interface_id: u32) -> bool {
    if (interface_id == rules_account::account::interface::IACCOUNT_ID) {
      true
    } else {
      false
    }
  }
}
