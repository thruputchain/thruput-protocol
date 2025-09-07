// A program to test the rpc driver, used in {s}rpcthroughput.
// This file is present in protocol/ to support cross-language RPC testing.

typedef opaque Data<>;
program blank_rpc
{
  version blank_rpc_v1
  {
    void null(void) = 0;
    Data echo(Data) = 1;
  }
  = 1;
}
= 3123124;
