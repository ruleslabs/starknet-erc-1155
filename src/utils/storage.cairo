use array::ArrayTrait;
use traits::{ Into, TryInto };
use option::OptionTrait;
use starknet::{
  StorageAccess,
  storage_address_from_base_and_offset,
  storage_read_syscall,
  storage_write_syscall,
  SyscallResult,
  StorageBaseAddress,
};

impl Felt252ArrayStorageAccess of StorageAccess<Array<felt252>> {
  fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult<Array<felt252>> {
    let mut arr = ArrayTrait::<felt252>::new();

    // Read array len
    let len: u8 = StorageAccess::<usize>::read(:address_domain, :base)?.try_into().expect('Storage - Array too large');

    // Load array content
    let mut i: u8 = 1;
    loop {
      if (i > len) {
        break ();
      }

      arr.append(storage_read_syscall(:address_domain, address: storage_address_from_base_and_offset(base, i))?);
      i += 1;
    };

    Result::Ok(arr)
  }

  fn write(address_domain: u32, base: StorageBaseAddress, value: Array<felt252>) -> SyscallResult<()> {
    // Assert array can fit in storage obj
    // 1 slots for the len; 255 slots for the array content
    let len: u8 = value.len().try_into().expect('Storage - Array too large');

    // Write array content
    let mut i: u8 = 1;
    loop {
      if (i > len) {
        break ();
      }

      storage_write_syscall(
        :address_domain,
        address: storage_address_from_base_and_offset(base, i),
        value: *value.at(len.into())
      );
      i += 1;
    };

    // Store array len
    StorageAccess::<felt252>::write(:address_domain, :base, value: len.into())
  }
}
