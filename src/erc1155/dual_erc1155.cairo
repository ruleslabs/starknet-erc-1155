use array::ArrayTrait;
use starknet::SyscallResultTrait;
use traits::Into;
use debug::PrintTrait;

// locals
use rules_utils::utils::serde::SerdeTraitExt;
use rules_utils::utils::try_selector_with_fallback;
use rules_utils::utils::unwrap_and_cast::UnwrapAndCast;

mod selectors {
  const uri: felt252 = 0x2ee3279dd30231650e0b4a1a3516ab3dc26b6d3dfcb6ef20fb4329cfc1213e1;

  const balance_of: felt252 = 0x35a73cd311a05d46deda634c5ee045db92f811b4e74bca4437fcb5302b7af33;
  const balanceOf: felt252 = 0x2e4263afad30923c891518314c3c95dbe830a16874e8abc5777a9a20b54c76e;

  const balance_of_batch: felt252 = 0x1a2485e0b7ff3ae0e24fcd6e1efb8ce3d36ef74703be26f9c337a04fca73988;
  const balanceOfBatch: felt252 = 0x116d888b0a9ad3998fcf1cdb2711375c69ac1847e806a480e3585c3da18eac3;

  const is_approved_for_all: felt252 = 0x2aa3ea196f9b8a4f65613b67fcf185e69d8faa9601a3382871d15b3060e30dd;
  const isApprovedForAll: felt252 = 0x21cdf9aedfed41bc4485ae779fda471feca12075d9127a0fc70ac6b3b3d9c30;

  const set_approval_for_all: felt252 = 0xd86ca3d41635e20c180181046b11abcf19e1bdef3dcaa4c180300ccca1813f;
  const setApprovalForAll: felt252 = 0x2d4c8ea4c8fb9f571d1f6f9b7692fff8e5ceaf73b1df98e7da8c1109b39ae9a;

  const safe_transfer_from: felt252 = 0x16f0218b33b5cf273196787d7cf139a9ad13d58e6674dcdce722b3bf8389863;
  const safeTransferFrom: felt252 = 0x19d59d013d4aa1a8b1ce4c8299086f070733b453c02d0dc46e735edc04d6444;

  const safe_batch_transfer_from: felt252 = 0x3556ee435402e506fc85acb898a9acb9daf2855fdec20673ec29a8cb1196cb7;
  const safeBatchTransferFrom: felt252 = 0x23cc35d21c405aa7adf1f3afcf558aec0dbe6a45cade725420609aef87e9035;

  const supports_interface: felt252 = 0xfe80f537b66d12a00b6d3c072b44afbb716e78dde5c3f0ef116ee93d3e3283;
  const supportsInterface: felt252 = 0x29e211664c0b63c79638fbea474206ca74016b3e9a3dc4f9ac300ffd8bdf2cd;
}

#[derive(Copy, Drop)]
struct DualCaseERC1155 {
  contract_address: starknet::ContractAddress
}

trait DualCaseERC1155Trait {
  fn uri(self: @DualCaseERC1155, token_id: u256) -> Span<felt252>;

  fn balance_of(self: @DualCaseERC1155, account: starknet::ContractAddress, id: u256) -> u256;

  fn balance_of_batch(self: @DualCaseERC1155, accounts: Span<starknet::ContractAddress>, ids: Span<u256>)-> Span<u256>;

  fn is_approved_for_all(
    self: @DualCaseERC1155,
    account: starknet::ContractAddress,
    operator: starknet::ContractAddress
  ) -> bool;

  fn set_approval_for_all(self: @DualCaseERC1155, operator: starknet::ContractAddress, approved: bool);

  fn safe_transfer_from(
    self: @DualCaseERC1155,
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    amount: u256,
    data: Span<felt252>
  );

  fn safe_batch_transfer_from(
    self: @DualCaseERC1155,
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    ids: Span<u256>,
    amounts: Span<u256>,
    data: Span<felt252>
  );

  fn supports_interface(self: @DualCaseERC1155, interface_id: felt252) -> bool;
}

impl DualCaseERC1155Impl of DualCaseERC1155Trait {
  fn uri(self: @DualCaseERC1155, token_id: u256) -> Span<felt252> {
    let mut args = array![];
    args.append_serde(token_id);

    starknet::call_contract_syscall(*self.contract_address, selectors::uri, args.span()).unwrap_and_cast()
  }

  fn balance_of(self: @DualCaseERC1155, account: starknet::ContractAddress, id: u256) -> u256 {
    let mut args = array![];
    args.append_serde(account);
    args.append_serde(id);

    try_selector_with_fallback(*self.contract_address, selectors::balance_of, selectors::balanceOf, args.span())
      .unwrap_and_cast()
  }

  fn balance_of_batch(
    self: @DualCaseERC1155,
    accounts: Span<starknet::ContractAddress>,
    ids: Span<u256>
  ) -> Span<u256> {
    let mut args = array![];
    args.append_serde(accounts);
    args.append_serde(ids);

    try_selector_with_fallback(
      *self.contract_address,
      selectors::balance_of_batch,
      selectors::balanceOfBatch,
      args.span()
    ).unwrap_and_cast()
  }

  fn is_approved_for_all(
    self: @DualCaseERC1155,
    account: starknet::ContractAddress,
    operator: starknet::ContractAddress
  ) -> bool {
    let mut args = array![];
    args.append_serde(account);
    args.append_serde(operator);

    try_selector_with_fallback(
      *self.contract_address,
      selectors::is_approved_for_all,
      selectors::isApprovedForAll,
      args.span()
    ).unwrap_and_cast()
  }

  fn set_approval_for_all(self: @DualCaseERC1155, operator: starknet::ContractAddress, approved: bool) {
    let mut args = array![];
    args.append_serde(operator);
    args.append_serde(approved);

    try_selector_with_fallback(
      *self.contract_address,
      selectors::set_approval_for_all,
      selectors::setApprovalForAll,
      args.span()
    ).unwrap_syscall();
  }

  fn safe_transfer_from(
    self: @DualCaseERC1155,
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    amount: u256,
    data: Span<felt252>
  ) {
    let mut args = array![];
    args.append_serde(from);
    args.append_serde(to);
    args.append_serde(id);
    args.append_serde(amount);
    args.append_serde(data);

    try_selector_with_fallback(
      *self.contract_address,
      selectors::safe_transfer_from,
      selectors::safeTransferFrom,
      args.span()
    ).unwrap_syscall();
  }

  fn safe_batch_transfer_from(
    self: @DualCaseERC1155,
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    ids: Span<u256>,
    amounts: Span<u256>,
    data: Span<felt252>
  ) {
    let mut args = array![];
    args.append_serde(from);
    args.append_serde(to);
    args.append_serde(ids);
    args.append_serde(amounts);
    args.append_serde(data);

    try_selector_with_fallback(
      *self.contract_address,
      selectors::safe_batch_transfer_from,
      selectors::safeBatchTransferFrom,
      args.span()
    ).unwrap_syscall();
  }

  fn supports_interface(self: @DualCaseERC1155, interface_id: felt252) -> bool {
    let mut args = array![];
    args.append_serde(interface_id);

    try_selector_with_fallback(
      *self.contract_address,
      selectors::supports_interface,
      selectors::supportsInterface,
      args.span()
    ).unwrap_and_cast()
  }
}
