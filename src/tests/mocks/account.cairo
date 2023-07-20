#[starknet::contract]
mod Account {
  use rules_account::account::interface::ISRC6_ID;

  #[storage]
  struct Storage { }

  #[constructor]
  fn constructor(ref self: ContractState) {}

  #[external(v0)]
  fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
    interface_id == ISRC6_ID
  }
}
