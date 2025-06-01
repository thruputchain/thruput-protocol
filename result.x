namespace hogd {

enum ResultType {
  Ok = 0,
  Err = 1,
};

union Result<T, E> switch (ResultType is_err) {
case Ok:
  T val;
case Err:
  E err;
};

}
