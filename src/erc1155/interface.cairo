use rules_erc1155::utils::serde::SpanSerde;

const IERC1155_ID: u32 = 0xd9b67a26_u32;
const IERC1155_METADATA_ID: u32 = 0x0e89341c_u32;
const IERC1155_RECEIVER_ID: u32 = 0x4e2312e0_u32;
const ON_ERC1155_RECEIVED_SELECTOR: u32 = 0xf23a6e61_u32;
const ON_ERC1155_BATCH_RECEIVED_SELECTOR: u32 = 0xbc197c81_u32;

#[abi]
trait IERC1155 {
  fn uri(tokenId: u256) -> Array<felt252>;

  fn supports_interface(interface_id: u32) -> bool;

  fn balance_of(account: starknet::ContractAddress, id: u256) -> u256;

  fn balance_of_batch(accounts: Span<starknet::ContractAddress>, ids: Span<u256>);

  fn set_approval_for_all(operator: starknet::ContractAddress, approved: bool);

  fn is_approved_for_all(account: starknet::ContractAddress, operator: starknet::ContractAddress) -> bool;

  fn safe_transfer_from(
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    amount: u256,
    data: Span<felt252>
  );

  fn safe_batch_transfer_from(
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    ids: Span<u256>,
    amounts: Span<u256>,
    data: Span<felt252>
  );
}

#[abi]
trait IERC1155Receiver {
  #[external]
  fn on_erc1155_received(
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    id: u256,
    value: u256,
    data: Span<felt252>
  ) -> u32;

  #[external]
  fn on_erc1155_batch_received(
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    ids: Span<u256>,
    values: Span<u256>,
    data: Span<felt252>
  ) -> u32;
}
