All syscalls can return error kFault if a user-supplied argument points to an
invalid contract memory address.

All syscalls that return a bytespan of non-static size (a [u8], as written
here) take as one of their arguments a contract-allocated bytespan, in which
the output argument should be written, AND return a RuntimeMemoryLength
variable, which describes the full length of the output. At most bytespan.len()
bytes are written into the contract-supplied bytespan; if the returned length
is greater than bytespan.len(), the output did not fit and was truncated, and
the contract should retry with a buffer of at least the returned length. We do
not change any of the remaining elements of the bytespan.
