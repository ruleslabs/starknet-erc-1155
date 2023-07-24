#[starknet::contract]
mod NonImplementingMock {
  #[storage]
  struct Storage {}

  #[external(v0)]
  fn noop(self: @ContractState) -> bool {
    false
  }
}
