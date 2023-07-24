#[starknet::contract]
mod SnakeERC1155ReceiverPanicMock {
  // locals
  use rules_erc1155::erc1155::interface::IERC1155Receiver;

  #[storage]
  struct Storage {}

    #[external(v0)]
  impl ERC1155ReceiverImpl of IERC1155Receiver<ContractState> {
    fn on_erc1155_received(
      ref self: ContractState,
      operator: starknet::ContractAddress,
      from: starknet::ContractAddress,
      id: u256,
      value: u256,
      data: Span<felt252>
    ) -> felt252 {
      panic_with_felt252('Some error');
      3
    }

    fn on_erc1155_batch_received(
      ref self: ContractState,
      operator: starknet::ContractAddress,
      from: starknet::ContractAddress,
      ids: Span<u256>,
      values: Span<u256>,
      data: Span<felt252>
    ) -> felt252 {
      panic_with_felt252('Some error');
      3
    }
  }
}

#[starknet::contract]
mod CamelERC1155ReceiverPanicMock {
  // locals
  use rules_erc1155::erc1155::interface::IERC1155ReceiverCamel;

  #[storage]
  struct Storage {}

  #[external(v0)]
  impl ERC1155ReceiverImpl of IERC1155ReceiverCamel<ContractState> {
    fn onERC1155Received(
      ref self: ContractState,
      operator: starknet::ContractAddress,
      from: starknet::ContractAddress,
      id: u256,
      value: u256,
      data: Span<felt252>
    ) -> felt252 {
      panic_with_felt252('Some error');
      3
    }

    fn onERC1155BatchReceived(
      ref self: ContractState,
      operator: starknet::ContractAddress,
      from: starknet::ContractAddress,
      ids: Span<u256>,
      values: Span<u256>,
      data: Span<felt252>
    ) -> felt252 {
      panic_with_felt252('Some error');
      3
    }
  }
}
