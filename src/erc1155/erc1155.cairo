#[starknet::interface]
trait ERC1155ABI<TContractState> {
  fn uri(self: @TContractState, token_id: u256) -> Span<felt252>;

  fn supports_interface(self: @TContractState, interface_id: u32) -> bool;

  fn balance_of(self: @TContractState, account: starknet::ContractAddress, id: u256) -> u256;

  fn balance_of_batch(self: @TContractState, accounts: Span<starknet::ContractAddress>, ids: Span<u256>) -> Array<u256>;

  fn is_approved_for_all(
    self: @TContractState,
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

#[starknet::contract]
mod ERC1155 {
  use array::{ Span, ArrayTrait, SpanTrait, ArrayDrop, SpanSerde };
  use option::OptionTrait;
  use traits::{ Into, TryInto };
  use zeroable::Zeroable;
  use starknet::contract_address::ContractAddressZeroable;
  use rules_account::account;

  // local
  use rules_erc1155::introspection::erc165;
  use rules_erc1155::introspection::erc165::{ ERC165, IERC165 };
  use rules_erc1155::erc1155;
  use rules_erc1155::erc1155::interface::IERC1155;
  use rules_utils::utils::storage::Felt252SpanStorageAccess;

  // Dispatchers
  use rules_erc1155::erc1155::interface::{ IERC1155ReceiverDispatcher, IERC1155ReceiverDispatcherTrait };
  use rules_erc1155::introspection::erc165::{ IERC165Dispatcher, IERC165DispatcherTrait };

  //
  // Storage
  //

  #[storage]
  struct Storage {
    _balances: LegacyMap<(u256, starknet::ContractAddress), u256>,
    _operator_approvals: LegacyMap<(starknet::ContractAddress, starknet::ContractAddress), bool>,
    _uri: Span<felt252>,
  }

  //
  // Events
  //

  #[event]
  #[derive(Drop, starknet::Event)]
  enum Event {
    TransferSingle: TransferSingle,
    TransferBatch: TransferBatch,
    ApprovalForAll: ApprovalForAll,
    URI: URI,
  }

  #[derive(Drop, starknet::Event)]
  struct TransferSingle {
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    value: u256,
  }

  #[derive(Drop, starknet::Event)]
  struct TransferBatch {
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    ids: Span<u256>,
    values: Span<u256>,
  }

  #[derive(Drop, starknet::Event)]
  struct ApprovalForAll {
    account: starknet::ContractAddress,
    operator: starknet::ContractAddress,
    approved: bool,
  }

  #[derive(Drop, starknet::Event)]
  struct URI {
    value: Span<felt252>,
    id: u256,
  }

  //
  // Constructor
  //

  #[constructor]
  fn constructor(ref self: ContractState, uri_: Span<felt252>) {
    self.initializer(uri_);
  }

  //
  // IERC1155 impl
  //

  #[external(v0)]
  impl IERC1155Impl of erc1155::interface::IERC1155<ContractState> {
    fn uri(self: @ContractState, token_id: u256) -> Span<felt252> {
      self._uri.read()
    }

    fn balance_of(self: @ContractState, account: starknet::ContractAddress, id: u256) -> u256 {
      self._balances.read((id, account))
    }

    fn balance_of_batch(
      self: @ContractState,
      accounts: Span<starknet::ContractAddress>,
      ids: Span<u256>
    ) -> Array<u256> {
      assert(accounts.len() == ids.len(), 'ERC1155: bad accounts & ids len');

      let mut batch_balances = ArrayTrait::<u256>::new();

      let mut i: usize = 0;
      let len = accounts.len();
      loop {
        if (i >= len) {
          break ();
        }

        batch_balances.append(self.balance_of(*accounts.at(i), *ids.at(i)));
        i += 1;
      };

      batch_balances
    }

    fn is_approved_for_all(
      self: @ContractState,
      account: starknet::ContractAddress,
      operator: starknet::ContractAddress
    ) -> bool {
      self._operator_approvals.read((account, operator))
    }

    fn set_approval_for_all(ref self: ContractState, operator: starknet::ContractAddress, approved: bool) {
      let caller = starknet::get_caller_address();

      self._set_approval_for_all(owner: caller, :operator, :approved);
    }

    fn safe_transfer_from(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      id: u256,
      amount: u256,
      data: Span<felt252>
    ) {
      let caller = starknet::get_caller_address();
      assert(
        (from == caller) | self.is_approved_for_all(account: from, operator: caller),
        'ERC1155: caller not allowed'
      );

      self._safe_transfer_from(:from, :to, :id, :amount, :data);
    }

    fn safe_batch_transfer_from(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      ids: Span<u256>,
      amounts: Span<u256>,
      data: Span<felt252>
    ) {
      let caller = starknet::get_caller_address();
      assert(
        (from == caller) | self.is_approved_for_all(account: from, operator: caller),
        'ERC1155: caller not allowed'
      );

      self._safe_batch_transfer_from(:from, :to, :ids, :amounts, :data);
    }
  }

  //
  // IERC165 impl
  //

  #[external(v0)]
  impl IERC165Impl of erc165::IERC165<ContractState> {
    fn supports_interface(self: @ContractState, interface_id: u32) -> bool {
      if (
        (interface_id == erc1155::interface::IERC1155_ID) |
        (interface_id == erc1155::interface::IERC1155_METADATA_ID)
      ) {
        true
      } else {
        let erc165_self = ERC165::unsafe_new_contract_state();

        erc165_self.supports_interface(:interface_id)
      }
    }
  }

  //
  // Helpers
  //

  #[generate_trait]
  impl HelperImpl of HelperTrait {
    fn initializer(ref self: ContractState, uri_: Span<felt252>) {
      self._set_uri(uri_);
    }

    fn _mint(ref self: ContractState, to: starknet::ContractAddress, id: u256, amount: u256, data: Span<felt252>) {
      assert(to.is_non_zero(), 'ERC1155: mint to 0 addr');
      let (ids, amounts) = self._as_singleton_spans(id, amount);
      self._update(from: Zeroable::zero(), :to, :ids, :amounts, :data);
    }

    fn _mint_batch(
      ref self: ContractState,
      to: starknet::ContractAddress,
      ids: Span<u256>,
      amounts: Span<u256>,
      data: Span<felt252>
    ) {
      assert(to.is_non_zero(), 'ERC1155: mint to 0 addr');
      self._update(from: Zeroable::zero(), :to, :ids, :amounts, :data);
    }

    // Burn

    fn _burn(ref self: ContractState, from: starknet::ContractAddress, id: u256, amount: u256) {
      assert(from.is_non_zero(), 'ERC1155: burn from 0 addr');
      let (ids, amounts) = self._as_singleton_spans(id, amount);
      self._update(:from, to: Zeroable::zero(), :ids, :amounts, data: ArrayTrait::new().span());
    }

    fn _burn_batch(ref self: ContractState, from: starknet::ContractAddress, ids: Span<u256>, amounts: Span<u256>) {
      assert(from.is_non_zero(), 'ERC1155: burn from 0 addr');
      self._update(:from, to: Zeroable::zero(), :ids, :amounts, data: ArrayTrait::new().span());
    }

    // Setters

    fn _set_uri(ref self: ContractState, new_uri: Span<felt252>) {
      self._uri.write(new_uri);
    }

    fn _set_approval_for_all(
      ref self: ContractState,
      owner: starknet::ContractAddress,
      operator: starknet::ContractAddress,
      approved: bool
    ) {
      assert(owner != operator, 'ERC1155: self approval');

      self._operator_approvals.write((owner, operator), approved);

      // Events
      self.emit(
        Event::ApprovalForAll(
          ApprovalForAll { account: owner, operator, approved }
        )
      );
    }

    // Balances update

    fn _update(
      ref self: ContractState,
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
          let from_balance = self._balances.read((id, from));
          assert(from_balance >= amount, 'ERC1155: insufficient balance');

          self._balances.write((id, from), from_balance - amount);
        }

        // Increase recipient balance
        if (to.is_non_zero()) {
          let to_balance = self._balances.read((id, to));
          self._balances.write((id, to), to_balance + amount);
        }

        i += 1;
      };

      // Safe transfer check
      if (to.is_non_zero()) {
        if (ids.len() == 1) {
          let id = *ids.at(0);
          let amount = *amounts.at(0);

          // Event
          self.emit(
            Event::TransferSingle(
              TransferSingle { operator, from, to, id, value: amount }
            )
          );

          self._do_safe_transfer_acceptance_check(:operator, :from, :to, :id, :amount, :data);
        } else {

          // Event
          self.emit(
            Event::TransferBatch(
              TransferBatch { operator, from, to, ids, values: amounts }
            )
          );

          self._do_safe_batch_transfer_acceptance_check(:operator, :from, :to, :ids, :amounts, :data);
        }
      }
    }

    fn _safe_transfer_from(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      id: u256,
      amount: u256,
      data: Span<felt252>
    ) {
      assert(to.is_non_zero(), 'ERC1155: transfer to 0 addr');
      assert(from.is_non_zero(), 'ERC1155: transfer from 0 addr');

      let (ids, amounts) = self._as_singleton_spans(id, amount);

      self._update(:from, :to, :ids, :amounts, :data);
    }

    fn _safe_batch_transfer_from(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      ids: Span<u256>,
      amounts: Span<u256>,
      data: Span<felt252>
    ) {
      assert(to.is_non_zero(), 'ERC1155: transfer to 0 addr');
      assert(from.is_non_zero(), 'ERC1155: transfer from 0 addr');

      self._update(:from, :to, :ids, :amounts, :data);
    }

    // Safe transfer check

    fn _do_safe_transfer_acceptance_check(
      ref self: ContractState,
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
        assert(ERC165.supports_interface(account::interface::IACCOUNT_ID), 'ERC1155: safe transfer failed');
      }
    }

    fn _do_safe_batch_transfer_acceptance_check(
      ref self: ContractState,
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
        assert(response == erc1155::interface::ON_ERC1155_BATCH_RECEIVED_SELECTOR, 'ERC1155: safe transfer failed');
      } else {
        assert(ERC165.supports_interface(account::interface::IACCOUNT_ID), 'ERC1155: safe transfer failed');
      }
    }

    // Utils

    fn _as_singleton_spans(self: @ContractState, element1: u256, element2: u256) -> (Span<u256>, Span<u256>) {
      let mut arr1 = ArrayTrait::<u256>::new();
      let mut arr2 = ArrayTrait::<u256>::new();

      arr1.append(element1);
      arr2.append(element2);

      (arr1.span(), arr2.span())
    }
  }
}
