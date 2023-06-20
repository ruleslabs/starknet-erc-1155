const SUCCESS: felt252 = 'SUCCESS';
const FAILURE: felt252 = 'FAILURE';

#[contract]
mod ERC1155Receiver {
  use array::SpanTrait;

  // locals
  use rules_erc1155::erc1155::interface::IERC1155Receiver;
  use rules_erc1155::erc1155::interface::IERC1155_RECEIVER_ID;
  use rules_erc1155::erc1155::interface::ON_ERC1155_RECEIVED_SELECTOR;
  use rules_erc1155::erc1155::interface::ON_ERC1155_BATCH_RECEIVED_SELECTOR;
  use rules_erc1155::introspection::erc165::ERC165;
  use rules_utils::utils::serde::SpanSerde;

  impl ERC1155ReceiverImpl of IERC1155Receiver {
    fn on_erc1155_received(
      operator: starknet::ContractAddress,
      from: starknet::ContractAddress,
      id: u256,
      value: u256,
      data: Span<felt252>
    ) -> u32 {
      if (*data.at(0) == super::SUCCESS) {
        ON_ERC1155_RECEIVED_SELECTOR
      } else {
        0
      }
    }

    fn on_erc1155_batch_received(
      operator: starknet::ContractAddress,
      from: starknet::ContractAddress,
      ids: Span<u256>,
      values: Span<u256>,
      data: Span<felt252>
    ) -> u32 {
      if (*data.at(0) == super::SUCCESS) {
        ON_ERC1155_BATCH_RECEIVED_SELECTOR
      } else {
        0
      }
    }
  }

  #[constructor]
  fn constructor() {
    ERC165::register_interface(IERC1155_RECEIVER_ID);
  }

  #[view]
  fn supports_interface(interface_id: u32) -> bool {
    ERC165::supports_interface(interface_id)
  }

  #[external]
  fn on_erc1155_received(
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    id: u256,
    value: u256,
    data: Span<felt252>
  ) -> u32 {
    ERC1155ReceiverImpl::on_erc1155_received(:operator, :from, :id, :value, :data)
  }

  #[external]
  fn on_erc1155_batch_received(
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    ids: Span<u256>,
    values: Span<u256>,
    data: Span<felt252>
  ) -> u32 {
    ERC1155ReceiverImpl::on_erc1155_batch_received(:operator, :from, :ids, :values, :data)
  }
}

#[contract]
mod ERC1155NonReceiver {}
