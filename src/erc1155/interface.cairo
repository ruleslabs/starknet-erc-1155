use array::SpanSerde;

const IERC1155_ID: felt252 = 0xd9b67a26;
const IERC1155_METADATA_ID: felt252 = 0x0e89341c;
const IERC1155_RECEIVER_ID: felt252 = 0x4e2312e0;
const ON_ERC1155_RECEIVED_SELECTOR: felt252 = 0xf23a6e61;
const ON_ERC1155_BATCH_RECEIVED_SELECTOR: felt252 = 0xbc197c81;

#[starknet::interface]
trait IERC1155<TContractState> {
  fn uri(self: @TContractState, token_id: u256) -> Span<felt252>;

  fn balance_of(self: @TContractState, account: starknet::ContractAddress, id: u256) -> u256;

  fn balance_of_batch(self: @TContractState, accounts: Span<starknet::ContractAddress>, ids: Span<u256>) -> Array<u256>;

  fn is_approved_for_all(self: @TContractState,
    account: starknet::ContractAddress,
    operator: starknet::ContractAddress
  ) -> bool;

  fn set_approval_for_all(ref self: TContractState, operator: starknet::ContractAddress, approved: bool);

  fn safe_transfer_from(
    ref self: TContractState,
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    amount: u256,
    data: Span<felt252>
  );

  fn safe_batch_transfer_from(
    ref self: TContractState,
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    ids: Span<u256>,
    amounts: Span<u256>,
    data: Span<felt252>
  );
}

// ERC1155 Receiver

#[starknet::interface]
trait IERC1155Receiver<TContractState> {
  fn on_erc1155_received(
    ref self: TContractState,
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    id: u256,
    value: u256,
    data: Span<felt252>
  ) -> felt252;

  fn on_erc1155_batch_received(
    ref self: TContractState,
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    ids: Span<u256>,
    values: Span<u256>,
    data: Span<felt252>
  ) -> felt252;
}

#[starknet::interface]
trait IERC1155ReceiverCamel<TContractState> {
  fn onERC1155Received(
    ref self: TContractState,
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    id: u256,
    value: u256,
    data: Span<felt252>
  ) -> felt252;

  fn onERC1155BatchReceived(
    ref self: TContractState,
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    ids: Span<u256>,
    values: Span<u256>,
    data: Span<felt252>
  ) -> felt252;
}
