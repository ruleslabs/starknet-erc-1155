#[starknet::contract]
mod SnakeERC1155PanicMock {
  use array::ArrayTrait;
  use zeroable::Zeroable;
  use rules_utils::introspection::interface::ISRC5;

  //locals
  use rules_erc1155::erc1155::interface::{ IERC1155, IERC1155Metadata };

  //
  // Storage
  //

  #[storage]
  struct Storage {}

  //
  // IERC1155 impl
  //

  #[external(v0)]
  impl IERC1155Impl of IERC1155<ContractState> {
    fn balance_of(self: @ContractState, account: starknet::ContractAddress, id: u256) -> u256 {
      panic_with_felt252('Some error');
      u256 { low: 3, high: 3 }
    }

    fn balance_of_batch(
      self: @ContractState,
      accounts: Span<starknet::ContractAddress>,
      ids: Span<u256>
    ) -> Span<u256> {
      panic_with_felt252('Some error');
      array![].span()
    }

    fn is_approved_for_all(
      self: @ContractState,
      account: starknet::ContractAddress,
      operator: starknet::ContractAddress
    ) -> bool {
      panic_with_felt252('Some error');
      false
    }

    fn set_approval_for_all(ref self: ContractState, operator: starknet::ContractAddress, approved: bool) {
      panic_with_felt252('Some error');
    }

    fn safe_transfer_from(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      id: u256,
      amount: u256,
      data: Span<felt252>
    ) {
      panic_with_felt252('Some error');
    }

    fn safe_batch_transfer_from(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      ids: Span<u256>,
      amounts: Span<u256>,
      data: Span<felt252>
    ) {
      panic_with_felt252('Some error');
    }
  }

  //
  // IERC1155 Metadata impl
  //

  #[external(v0)]
  impl IERC1155MetadataImpl of IERC1155Metadata<ContractState> {
    fn uri(self: @ContractState, token_id: u256) -> Span<felt252> {
      panic_with_felt252('Some error');
      array![].span()
    }
  }

  //
  // ISRC5 impl
  //

  #[external(v0)]
  impl ISRC5Impl of ISRC5<ContractState> {
    fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
      panic_with_felt252('Some error');
      false
    }
  }
}

#[starknet::contract]
mod CamelERC1155PanicMock {
  use array::ArrayTrait;
  use zeroable::Zeroable;
  use rules_utils::introspection::interface::ISRC5Camel;

  //locals
  use rules_erc1155::erc1155::interface::{ IERC1155, IERC1155Camel, IERC1155CamelOnly, IERC1155Metadata };

  //
  // Storage
  //

  #[storage]
  struct Storage {}

  //
  // IERC1155 impl
  //

  #[external(v0)]
  impl IERC1155CamelImpl of IERC1155Camel<ContractState> {
    fn balanceOf(self: @ContractState, account: starknet::ContractAddress, id: u256) -> u256 {
      panic_with_felt252('Some error');
      u256 { low: 3, high: 3 }
    }

    fn balanceOfBatch(
      self: @ContractState,
      accounts: Span<starknet::ContractAddress>,
      ids: Span<u256>
    ) -> Span<u256> {
      panic_with_felt252('Some error');
      array![].span()
    }

    fn isApprovedForAll(
      self: @ContractState,
      account: starknet::ContractAddress,
      operator: starknet::ContractAddress
    ) -> bool {
      panic_with_felt252('Some error');
      false
    }

    fn setApprovalForAll(ref self: ContractState, operator: starknet::ContractAddress, approved: bool) {
      panic_with_felt252('Some error');
    }

    fn safeTransferFrom(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      id: u256,
      amount: u256,
      data: Span<felt252>
    ) {
      panic_with_felt252('Some error');
    }

    fn safeBatchTransferFrom(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      ids: Span<u256>,
      amounts: Span<u256>,
      data: Span<felt252>
    ) {
      panic_with_felt252('Some error');
    }
  }

  //
  // IERC1155 Metadata impl
  //

  #[external(v0)]
  impl IERC1155MetadataImpl of IERC1155Metadata<ContractState> {
    fn uri(self: @ContractState, token_id: u256) -> Span<felt252> {
      panic_with_felt252('Some error');
      array![].span()
    }
  }

  //
  // ISRC5 impl
  //

  #[external(v0)]
  impl ISRC5CamelImpl of ISRC5Camel<ContractState> {
    fn supportsInterface(self: @ContractState, interfaceId: felt252) -> bool {
      panic_with_felt252('Some error');
      false
    }
  }
}
