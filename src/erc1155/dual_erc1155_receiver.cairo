use array::ArrayTrait;
use starknet::SyscallResultTrait;
use rules_utils::utils::try_selector_with_fallback;
use rules_utils::utils::serde::SerdeTraitExt;
use rules_utils::utils::unwrap_and_cast::UnwrapAndCast;

mod selectors {
  const on_erc1155_received: felt252 = 0x29f7b9dd8d59017707416b980de53857e6e64cf1a20d2a072a65376642f3e4a;
  const on_erc1155_batch_received: felt252 = 0x381257cd6335468beb8f1c9f002f0e45a95372d0a06d6b4b181ab48e0cccb20;

  const onERC1155Received: felt252 = 0x257262e6207ca1811ef54c3529033f183305f6a2fd0e74317bd16230a4c65c0;
  const onERC1155BatchReceived: felt252 = 0x392b0d298d7b4acb75ad17d06aac61214639a2540b3eed511563d5a1b9fcd3c;
}

#[derive(Copy, Drop)]
struct DualCaseERC1155Receiver {
  contract_address: starknet::ContractAddress
}

trait DualCaseERC1155ReceiverTrait {
  fn on_erc1155_received(
    self: @DualCaseERC1155Receiver,
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    id: u256,
    value: u256,
    data: Span<felt252>
  ) -> felt252;

  fn on_erc1155_batch_received(
    self: @DualCaseERC1155Receiver,
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    ids: Span<u256>,
    values: Span<u256>,
    data: Span<felt252>
  ) -> felt252;
}

impl DualCaseERC1155ReceiverImpl of DualCaseERC1155ReceiverTrait {
  fn on_erc1155_received(
    self: @DualCaseERC1155Receiver,
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    id: u256,
    value: u256,
    data: Span<felt252>
  ) -> felt252 {
    let mut args = array![];
    args.append_serde(operator);
    args.append_serde(from);
    args.append_serde(id);
    args.append_serde(value);
    args.append_serde(data);

    try_selector_with_fallback(
      *self.contract_address,
      selectors::on_erc1155_received,
      selectors::onERC1155Received,
      args.span()
    ).unwrap_and_cast()
  }

  fn on_erc1155_batch_received(
    self: @DualCaseERC1155Receiver,
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    ids: Span<u256>,
    values: Span<u256>,
    data: Span<felt252>
  ) -> felt252 {
    let mut args = array![];
    args.append_serde(operator);
    args.append_serde(from);
    args.append_serde(ids);
    args.append_serde(values);
    args.append_serde(data);

    try_selector_with_fallback(
      *self.contract_address,
      selectors::on_erc1155_batch_received,
      selectors::onERC1155BatchReceived,
      args.span()
    ).unwrap_and_cast()
  }
}
