use erc1155::utils::serde::SpanSerde;

const IERC1155_ID: u32 = 0xd9b67a26_u32;
const IERC1155_METADATA_ID: u32 = 0x0e89341c_u32;
const IERC1155_RECEIVER_ID: u32 = 0x4e2312e0_u32;
const ON_ERC1155_RECEIVED_SELECTOR: u32 = 0xf23a6e61_u32;
const ON_ERC1155_BATCH_RECEIVED_SELECTOR: u32 = 0xbc197c81_u32;

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
