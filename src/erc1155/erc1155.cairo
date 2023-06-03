#[abi]
trait ERC1155ABI {
  fn uri(tokenId: u256) -> Array<felt252>;

  fn supports_interface(interface_id: u32) -> bool;
}

#[contract]
mod ERC1155 {
  use array::{ Span, ArrayTrait, SpanTrait, ArrayDrop };
  use option::OptionTrait;
  use traits::{ Into, TryInto };
  use zeroable::Zeroable;
  use starknet::contract_address::ContractAddressZeroable;
  use rules_account::account;

  // local
  use rules_erc1155::utils::serde::SpanSerde;
  use rules_erc1155::introspection::erc165::ERC165;
  use rules_erc1155::erc1155;
  use rules_erc1155::utils::storage::Felt252SpanStorageAccess;

  // Dispatchers
  use super::super::interface::IERC1155ReceiverDispatcher;
  use super::super::interface::IERC1155ReceiverDispatcherTrait;
  use rules_erc1155::introspection::erc165::IERC165Dispatcher;
  use rules_erc1155::introspection::erc165::IERC165DispatcherTrait;

  //
  // Storage
  //

  struct Storage {
    _balances: LegacyMap<(u256, starknet::ContractAddress), u256>,
    _operator_approvals: LegacyMap<(starknet::ContractAddress, starknet::ContractAddress), bool>,
    _uri: Span<felt252>,
  }

  //
  // Events
  //

  #[event]
  fn TransferSingle(
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    value: u256
  ) {}

  #[event]
  fn TransferBatch(
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    ids: Span<u256>,
    values: Span<u256>
  ) {}

  #[event]
  fn ApprovalForAll(
    account: starknet::ContractAddress,
    operator: starknet::ContractAddress,
    approved: bool
  ) {}

  #[event]
  fn URI(
    value: Array<felt252>,
    id: u256
  ) {}

  //
  // Constructor
  //

  #[constructor]
  fn constructor(uri_: Span<felt252>) {
    initializer(uri_)
  }

  //
  // Interface impl
  //

  impl ERC1155 of erc1155::interface::IERC1155 {
    fn uri(tokenId: u256) -> Span<felt252> {
      _uri::read()
    }

    fn supports_interface(interface_id: u32) -> bool {
      if (
        interface_id == erc1155::interface::IERC1155_ID |
        interface_id == erc1155::interface::IERC1155_METADATA_ID
      ) {
        true
      } else {
        ERC165::supports_interface(interface_id)
      }
    }

    fn balance_of(account: starknet::ContractAddress, id: u256) -> u256 {
      _balances::read((id, account))
    }

    fn balance_of_batch(accounts: Span<starknet::ContractAddress>, ids: Span<u256>) -> Array<u256> {
      assert(accounts.len() == ids.len(), 'ERC1155: bad accounts & ids len');

      let mut batch_balances = ArrayTrait::<u256>::new();

      let mut i: usize = 0;
      let len = accounts.len();
      loop {
        if (i >= len) {
          break ();
        }

        batch_balances.append(balance_of(*accounts.at(i), *ids.at(i)));
        i += 1;
      };

      batch_balances
    }

    fn set_approval_for_all(operator: starknet::ContractAddress, approved: bool) {
      let caller = starknet::get_caller_address();

      _set_approval_for_all(owner: caller, :operator, :approved);
    }

    fn is_approved_for_all(account: starknet::ContractAddress, operator: starknet::ContractAddress) -> bool {
      _operator_approvals::read((account, operator))
    }

    fn safe_transfer_from(
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      id: u256,
      amount: u256,
      data: Span<felt252>
    ) {
      let caller = starknet::get_caller_address();
      assert(from == caller | is_approved_for_all(account: from, operator: caller), 'ERC1155: caller not allowed');

      _safe_transfer_from(:from, :to, :id, :amount, :data);
    }

    fn safe_batch_transfer_from(
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      ids: Span<u256>,
      amounts: Span<u256>,
      data: Span<felt252>
    ) {
      let caller = starknet::get_caller_address();
      assert(from == caller | is_approved_for_all(account: from, operator: caller), 'ERC1155: caller not allowed');

      _safe_batch_transfer_from(:from, :to, :ids, :amounts, :data);
    }
  }

  //
  // Getters
  //

  #[view]
  fn uri(tokenId: u256) -> Span<felt252> {
    ERC1155::uri(:tokenId)
  }

  // ERC165

  #[view]
  fn supports_interface(interface_id: u32) -> bool {
    ERC1155::supports_interface(:interface_id)
  }

  // Balance

  #[view]
  fn balance_of(account: starknet::ContractAddress, id: u256) -> u256 {
    ERC1155::balance_of(:account, :id)
  }

  #[view]
  fn balance_of_batch(accounts: Span<starknet::ContractAddress>, ids: Span<u256>) -> Array<u256> {
    ERC1155::balance_of_batch(:accounts, :ids)
  }

  // Approval

  #[external]
  fn set_approval_for_all(operator: starknet::ContractAddress, approved: bool) {
    ERC1155::set_approval_for_all(:operator, :approved)
  }

  #[view]
  fn is_approved_for_all(account: starknet::ContractAddress, operator: starknet::ContractAddress) -> bool {
    ERC1155::is_approved_for_all(:account, :operator)
  }

  // Transfer

  #[external]
  fn safe_transfer_from(
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    amount: u256,
    data: Span<felt252>
  ) {
    ERC1155::safe_transfer_from(:from, :to, :id, :amount, :data)
  }

  #[external]
  fn safe_batch_transfer_from(
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    ids: Span<u256>,
    amounts: Span<u256>,
    data: Span<felt252>
  ) {
    ERC1155::safe_batch_transfer_from(:from, :to, :ids, :amounts, :data)
  }

  //
  // Internals
  //

  // Init

  #[internal]
  fn initializer(uri_: Span<felt252>) {
    _set_URI(uri_);
  }

  // Mint

  #[internal]
  fn _mint(to: starknet::ContractAddress, id: u256, amount: u256, data: Span<felt252>) {
    assert(to.is_non_zero(), 'ERC1155: mint to 0 addr');
    let (ids, amounts) = _as_singleton_spans(id, amount);
    _update(from: Zeroable::zero(), :to, :ids, :amounts, :data);
  }

  #[internal]
  fn _mint_batch(to: starknet::ContractAddress, ids: Span<u256>, amounts: Span<u256>, data: Span<felt252>) {
    assert(to.is_non_zero(), 'ERC1155: mint to 0 addr');
    _update(from: Zeroable::zero(), :to, :ids, :amounts, :data);
  }

  // Burn

  #[internal]
  fn _burn(from: starknet::ContractAddress, id: u256, amount: u256, data: Span<felt252>) {
    assert(from.is_non_zero(), 'ERC1155: burn from 0 addr');
    let (ids, amounts) = _as_singleton_spans(id, amount);
    _update(:from, to: Zeroable::zero(), :ids, :amounts, :data);
  }

  #[internal]
  fn _burn_batch(from: starknet::ContractAddress, ids: Span<u256>, amounts: Span<u256>, data: Span<felt252>) {
    assert(from.is_non_zero(), 'ERC1155: burn from 0 addr');
    _update(:from, to: Zeroable::zero(), :ids, :amounts, :data);
  }

  // Setters

  #[internal]
  fn _set_URI(new_URI: Span<felt252>) {
      _uri::write(new_URI);
  }

  #[internal]
  fn _set_approval_for_all(owner: starknet::ContractAddress, operator: starknet::ContractAddress, approved: bool) {
    assert(owner != operator, 'ERC1155: self approval');

    _operator_approvals::write((owner, operator), approved);

    // Events
    ApprovalForAll(account: owner, :operator, :approved);
  }

  // Balances update

  #[internal]
  fn _update(
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    mut ids: Span<u256>,
    amounts: Span<u256>,
    data: Span<felt252>
  ) {
    assert(ids.len() == amounts.len(), 'ERC1155: bad ids & amounts len');

    let operator = starknet::get_caller_address();

    let mut i: usize = 0;
    let len = ids.len();
    loop {
      if (i >= len) {
        break ();
      }

      let id = *ids.at(i);
      let amount = *amounts.at(i);

      // Decrease sender balance
      if (from.is_non_zero()) {
        let from_balance = _balances::read((id, from));
        assert(from_balance >= amount, 'ERC1155: insufficient balance');

        _balances::write((id, from), from_balance - amount);
      }

      // Increase recipient balance
      if (to.is_non_zero()) {
        let to_balance = _balances::read((id, from));
        _balances::write((id, to), to_balance + amount);
      }

      i += 1;
    };

    // Safe transfer check
    if (to.is_non_zero()) {
      if (ids.len() == 1) {
        let id = *ids.at(0);
        let amount = *amounts.at(0);

        // Event
        TransferSingle(:operator, :from, :to, :id, value: amount);

        _do_safe_transfer_acceptance_check(:operator, :from, :to, :id, :amount, :data);
      } else {

        // Event
        TransferBatch(:operator, :from, :to, :ids, values: amounts);

        _do_safe_batch_transfer_acceptance_check(:operator, :from, :to, :ids, :amounts, :data);
      }
    }
  }

  #[internal]
  fn _safe_transfer_from(
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    amount: u256,
    data: Span<felt252>
  ) {
    assert(to.is_non_zero(), 'ERC1155: transfer to 0 addr');
    assert(from.is_non_zero(), 'ERC1155: transfer from 0 addr');

    let (ids, amounts) = _as_singleton_spans(id, amount);

    _update(:from, :to, :ids, :amounts, :data);
  }

  #[internal]
  fn _safe_batch_transfer_from(
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    ids: Span<u256>,
    amounts: Span<u256>,
    data: Span<felt252>
  ) {
    assert(to.is_non_zero(), 'ERC1155: transfer to 0 addr');
    assert(from.is_non_zero(), 'ERC1155: transfer from 0 addr');

    _update(:from, :to, :ids, :amounts, :data);
  }

  // Safe transfer check

  #[internal]
  fn _do_safe_transfer_acceptance_check(
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    amount: u256,
    data: Span<felt252>
  ) {
    let ERC165 = IERC165Dispatcher { contract_address: to };

    if (ERC165.supports_interface(erc1155::interface::IERC1155_RECEIVER_ID)) {
      // TODO: add casing fallback mechanism

      let ERC1155Receiver = IERC1155ReceiverDispatcher { contract_address: to };

      let response = ERC1155Receiver.on_erc1155_received(:operator, :from, :id, value: amount, :data);
      assert(response == erc1155::interface::ON_ERC1155_RECEIVED_SELECTOR, 'ERC1155: safe transfer failed');
    } else {
      assert(
        ERC165.supports_interface(account::interface::IACCOUNT_ID) == true,
        'ERC1155: safe transfer failed'
      );
    }
  }

  #[internal]
  fn _do_safe_batch_transfer_acceptance_check(
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    ids: Span<u256>,
    amounts: Span<u256>,
    data: Span<felt252>
  ) {
    let ERC165 = IERC165Dispatcher { contract_address: to };

    if (ERC165.supports_interface(erc1155::interface::IERC1155_RECEIVER_ID)) {
      // TODO: add casing fallback mechanism

      let ERC1155Receiver = IERC1155ReceiverDispatcher { contract_address: to };

      let response = ERC1155Receiver.on_erc1155_batch_received(:operator, :from, :ids, values: amounts, :data);
      assert(response == erc1155::interface::ON_ERC1155_RECEIVED_SELECTOR, 'ERC1155: safe transfer failed');
    } else {
      assert(
        ERC165.supports_interface(account::interface::IACCOUNT_ID) == true,
        'ERC1155: safe transfer failed'
      );
    }
  }

  // Utils

  #[internal]
  fn _as_singleton_spans(element1: u256, element2: u256) -> (Span<u256>, Span<u256>) {
    let mut arr1 = ArrayTrait::<u256>::new();
    let mut arr2 = ArrayTrait::<u256>::new();

    arr1.append(element1);
    arr2.append(element2);

    (arr1.span(), arr2.span())
  }
}
