use array::{ ArrayTrait, SpanTrait };
use traits::PartialEq;

impl SpanPartialEq<T, impl TPartialEq: PartialEq<T>, impl TCopy: Copy<T>, impl TDrop: Drop<T>> of PartialEq<Span<T>> {
  fn eq(lhs: Span<T>, rhs: Span<T>) -> bool {
    if (lhs.len() != rhs.len()) {
      // diff len

      false
    } else {
      // same len, we compare array content

      let mut eq = true;

      let mut i: usize = 0;
      let len = lhs.len();
      loop {
        if (i >= len) {
          break ();
        } else if (*lhs.at(i) != *rhs.at(i)) {
          eq = false;
          break ();
        }

        i += 1;
      };

      eq
    }
  }

  #[inline(always)]
  fn ne(lhs: Span<T>, rhs: Span<T>) -> bool {
    !(lhs == rhs)
  }
}
